"""Offline contract and additive-SQL migration checks. No production access."""
import json
import re
import sqlite3
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = (ROOT / 'lib/core/database/compatibility_schema.dart').read_text()


def statements():
    section = SCHEMA.split('static const createStatements = <String>[', 1)[1].split('\n  ];', 1)[0]
    pattern = r"'''(.*?)'''|'([^'\n]*)'"
    return [triple or single for triple, single in re.findall(pattern, section, re.S)]


def added_columns():
    section = SCHEMA.split('static const addedColumns = {', 1)[1].split('\n  };', 1)[0]
    result = {}
    for table, body in re.findall(r"'([a-z_]+)': \{(.*?)\}", section, re.S):
        result[table] = [(m[0], m[2]) for m in re.findall(r"'([a-z_]+)':\s*([\"'])(.*?)\2", body)]
    return result


def upgrade(db):
    with db:
        for table, additions in added_columns().items():
            existing = {r[1] for r in db.execute(f'PRAGMA table_info({table})')}
            for name, definition in additions:
                if name not in existing:
                    db.execute(f'ALTER TABLE {table} ADD COLUMN {name} {definition}')
        for statement in statements():
            db.execute(statement)
        db.execute("UPDATE invoices SET entry_mode=CASE WHEN is_manual_amount=1 THEN 'amount' ELSE 'products' END WHERE entry_mode IS NULL")


def v1_database():
    db = sqlite3.connect(':memory:')
    source = (ROOT / 'lib/core/database/database_impl.dart').read_text()
    for statement in re.findall(r"customStatement\('''(.*?)'''\)", source, re.S):
        if statement.strip().upper().startswith('CREATE'):
            db.execute(statement)
    return db


class AlignmentTests(unittest.TestCase):
    def setUp(self):
        self.db = v1_database()

    def tearDown(self):
        self.db.close()

    def test_v1_upgrade_preserves_all_preexisting_rows_and_outbox(self):
        d = self.db
        d.execute("INSERT INTO customers VALUES ('c','default','Test','010','note',7,100,101,NULL)")
        d.execute("INSERT INTO invoices VALUES ('i','default','c','INV-1','posted',80000,5000,'note',1,100,NULL,3,100,101,NULL)")
        d.execute("INSERT INTO invoice_items VALUES ('li','i',NULL,'Item',2,40000,0,100)")
        d.execute("INSERT INTO payments VALUES ('p','default','c',25000,'receipt',100,'operation-1',2,100,101,NULL)")
        d.execute("INSERT INTO ledger_entries VALUES ('e','default','c','p','payment_receipt',-25000,'receipt',100,100)")
        d.execute("INSERT INTO sync_outbox VALUES ('op','default','payment','p','create','{}',0,100,2,NULL,'pending','retry')")
        d.execute("INSERT INTO sync_state VALUES ('default','cursor-12',90,1,NULL,100)")
        tables = ['customers','invoices','invoice_items','payments','ledger_entries','sync_outbox','sync_state']
        columns = {t: [r[1] for r in d.execute(f'PRAGMA table_info({t})')] for t in tables}
        old = {t: d.execute(f'SELECT {",".join(columns[t])} FROM {t}').fetchall() for t in tables}
        upgrade(d)
        upgrade(d)
        for t in tables:
            self.assertEqual(old[t], d.execute(f'SELECT {",".join(columns[t])} FROM {t}').fetchall(), t)
        self.assertEqual(('amount','credit'), d.execute('SELECT entry_mode,method FROM invoices').fetchone())
        self.assertEqual('', d.execute('SELECT address FROM customers').fetchone()[0])
        self.assertEqual('ok', d.execute('PRAGMA integrity_check').fetchone()[0])

    def test_all_seven_public_cache_tables_match_captured_column_names(self):
        upgrade(self.db)
        catalog = json.loads((ROOT / 'db_structure/schema_catalog.json').read_text())
        public_tables = [t for t in catalog['tables'] if t['schema']=='public' and t['name'].startswith('elnota_')]
        self.assertEqual(7, len(public_tables))
        for table in public_tables:
            actual = {r[1] for r in self.db.execute(f'PRAGMA table_info({table["name"]})')}
            expected = {c['name'] for c in table['columns']}
            self.assertEqual(expected, actual, table['name'])

    def test_flutter_extra_fields_and_tables_survive(self):
        upgrade(self.db)
        for table, required in {
            'products': {'barcode','image','archived','category','box_quantity','item_number','price_missing','unit_price_minor','source_json'},
            'invoices': {'total_minor','discount_minor','status','version','method','entry_mode','source_json'},
            'payments': {'idempotency_key','legacy_invoice_id','source_json'},
            'installment_plans': {'installment_count','total_minor','start_date'},
            'business_settings': {'business_name','phone','address','currency'},
        }.items():
            actual = {r[1] for r in self.db.execute(f'PRAGMA table_info({table})')}
            self.assertTrue(required <= actual, table)
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO products(id,workspace_id,name,unit_price_minor,created_at,updated_at) VALUES ('p','w','x',-1,1,1)")

    def test_contract_remote_names_exist_in_reference_and_read_adapter_has_no_writes(self):
        catalog = json.loads((ROOT / 'db_structure/schema_catalog.json').read_text())
        names = {t['name'] for k in ['tables','views','functions'] for t in catalog[k] if t['schema']=='public'}
        dart = (ROOT / 'lib/core/database/web_contract.dart').read_text()
        for name in re.findall(r"static const \w+ = '(elnota_[a-z_]+)'", dart):
            self.assertIn(name, names)
        adapter = (ROOT / 'lib/core/network/web_read_repository.dart').read_text()
        self.assertNotRegex(adapter, r'\.(insert|upsert|update|delete|rpc)\(')
        self.assertEqual(4, adapter.count(".eq('user_id', _userId)"))
        preview = (ROOT / 'lib/core/database/web_compatibility_repository.dart').read_text()
        self.assertNotRegex(preview, r'(INSERT INTO|UPDATE|DELETE FROM) (customers|invoices|payments|ledger_entries|sync_outbox)\b')


if __name__ == '__main__':
    unittest.main(verbosity=2)
