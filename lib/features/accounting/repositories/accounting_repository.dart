import '../../../core/database/app_database.dart';
import '../../../core/database/database_impl.dart';
import '../models/accounting_snapshot.dart';
class AccountingRepository {
  AccountingRepository({AppDao? dao}):dao=dao??DatabaseService.to.dao;
  final AppDao dao;
  Stream<AccountingSnapshot> watch()=>dao.watchWorkspaceData().map(AccountingSnapshot.fromTables);
  Future<AccountingSnapshot> read() async=>AccountingSnapshot.fromTables(await dao.readWorkspaceData());
  void refresh()=>dao.refresh();
  Future<void> saveBusiness(BusinessInfo info)=>dao.saveBusinessSettings(businessName:info.name,phone:info.phone,address:info.address);
}
