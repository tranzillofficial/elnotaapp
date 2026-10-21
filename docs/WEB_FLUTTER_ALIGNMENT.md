# توحيد بيانات النوتة بين Flutter والموقع

## نطاق التعديل الحالي

بناءً على توجيه صاحب المشروع: Flutter هو الأساس الأشمل. التنفيذ الحالي يضيف توافق أسماء البيانات والجداول وتجهيزات الدمج إلى `elnotaapp` فقط. لا يوجد دمج تلقائي لبيانات العملاء أو ترحيل لقاعدة الإنتاج أو تعديل لريبو الموقع. لا يوجد ربط تلقائي بالسحابة عند تشغيل التطبيق.

المرجع: نسخة `elnota` المقروءة للمقارنة، و`db_structure/schema_catalog.json` و`elnota_schema_reference.sql`، الملتقطان بتاريخ 2026-10-20. هذه مراجع وليست إثباتًا لفحص قاعدة الإنتاج الآن. لا تتضمن هذه المهمة قراءة صفوف العملاء من قاعدة الإنتاج.

## الفرق الفعلي بين المشروعين

الموقع يحفظ بيانات العمل داخل JSONB في `elnota_cloud.data`، ويستخدم revision مع RPC للحماية من استبدال نسخة أحدث. لا توجد فيه حاليًا جداول PostgreSQL للعملاء والمنتجات والفواتير. Flutter يستخدم جداول SQLite محلية للحسابات، ومبالغ صحيحة بالقروش، ودفتر أستاذ وoutbox. لذلك لا يصح إعادة تسمية `customers` إلى `elnota_accounts` أو إلغاء الجداول المحلية لمجرد توحيد الأسماء؛ حساب صاحب المتجر مختلف عن عميل المتجر.

التوحيد يتم عند حدود البيانات: أسماء الجداول السحابية والأعمدة كما هي، وأسماء مفاتيح JSON كما هي، مع تحويل صريح إلى أسماء وأموال Flutter. لا يتم تغيير الأسماء المحلية القائمة بصورة تكسر تثبيتًا قديمًا.

## جداول الموقع

أضيفت نماذج وحدود قراءة، وجداول cache محلية بنفس **أسماء الأعمدة**:

| جدول الموقع/الـcache | الاستخدام | بيانات إضافية مهمة |
|---|---|---|
| `elnota_accounts` | حساب صاحب النشاط | `user_id`, `business_name`, `activated_at`, `cloud_until`, `cloud_plan`, `printing_enabled`, `suspended_at`, `deleted_at`, وحقول التفعيل المحفوظة أثناء الإيقاف |
| `elnota_requests` | طلبات التفعيل والاشتراك | `plan`, `amount`, `phone`, `reference`, `status`, `submitted_email`, `submitted_business_name`, `reviewed_at`, `reviewed_by` |
| `elnota_cloud` | الوثيقة الحالية | `user_id`, `data`, `revision`, `updated_at` |
| `elnota_backups` | نسخ سابقة | `id`, `user_id`, `data`, `revision`, `created_at` |
| `elnota_daily_backups` | أحدث نسخة يومية | `user_id`, `data`, `revision`, `updated_at` |
| `elnota_device_backup_files` | نسخ الأجهزة | `device_id`, `backup_day`, `captured_at`, `uploaded_at`, `size_bytes`, `data` |
| `elnota_catalog_imports` | كتالوج مخصص للحساب | `id`, `user_id`, `payload`, `created_at` |

الـcache محلي فقط، وليس بديلًا عن صلاحيات السيرفر. timestamps/UUID/JSONB لها تمثيل TEXT محلي، وbooleans تمثل كـINTEGER. `amount` و`size_bytes` مجرد قيم cache وليستا generated columns محلية. صلاحية الطباعة والتفعيل وهوية مقدم الطلب يجب أن يقررها السيرفر عند الربط؛ لا تمنحها إضافة صف محلي.

`elnota_latest_device_backups` اسم view مسجل في العقد، وليس جدولًا جديدًا. `elnota_private.admin_emails` و`account_actions` بيانات إدارية خاصة بالسيرفر ولا يتم نسخها للتطبيق.

كل أسماء RPC الحالية موجودة في `ElnotaWebContract`. وجود الاسم لا يعني استدعاءه: محول `WebReadRepository` غير مسجل عند startup ولا يحتوي على مسارات كتابة أو استدعاءات RPC. يأخذ هوية الحساب من جلسة Supabase، ويقيّد القراءات بها، مع حدود صفحات صريحة.

## الحقول الموحدة

| كيان الموقع | حقول الموقع | المقابل المحلي في Flutter |
|---|---|---|
| العميل | `id`, `name`, `phone`, `address`, `notes` | نفس الحقول؛ أضيف `address` للنموذج والتخزين والنموذج المرئي |
| المنتج | `id`, `name`, `price`, `barcode`, `image`, `archived`, `category`, `boxQuantity`, `itemNumber`, `priceMissing` | `products`: `unit_price_minor`, `barcode`, `image`, `archived`, `category`, `box_quantity`, `item_number`, `price_missing` |
| الفاتورة | `number`, `customerId`, `date`, `dueDate`, `notes`, `method`, `entryMode`, `voided` | `invoice_number`, `customer_id`, `invoice_date`, `due_date`, `notes`, `method`, `entry_mode`, `status` |
| بنود الفاتورة | `productId`, `name`, `price`, `quantity` | `product_id`, `description`, `unit_price_minor`, `quantity` |
| الدفعة | `id`, `amount`, `date`, `note`, `customerId` للحساب | `id`, `amount_minor`, `payment_date`, `notes`, `customer_id` |
| التقسيط | `months`, `financedAmount`, `firstDueDate` | `installment_count`, `total_minor`, `start_date` |
| إعدادات النشاط | `businessName`, `phone`, `address`, `currency` | `business_name`, `phone`, `address`, `currency` داخل `business_settings` |

`method`: `cash / credit / installment` مختلف عن `status`: `draft / posted / voided`. لا يُستبدل أحدهما بالآخر. قاعدة الإصدار القديم لم تكن تخزن method؛ القيمة الافتراضية المحلية `credit` لا تستنتج طريقة دفع تاريخية جديدة. `entryMode` يتحدد من `is_manual_amount` فقط. الفواتير الجديدة القائمة تظل تعمل، وأي كتابة مستقبلية لـmethod/entry_mode يجب أن تمر بعقد المستودع الكامل قبل تفعيل نقل البيانات.

حقول الوثيقة الجذرية محفوظة: `schemaVersion`, `syncImages`, `customers`, `products`, `invoices`, `customerPayments`, `settings`, `updatedAt`, `categories`, `fourFieldCatalog`, `catalogImports`. يحتفظ قارئ الوثيقة بأي حقول إضافية غير معروفة؛ لا يحذف الصور أو تواريخ الاستحقاق أو خطط الأقساط أو روابط استيراد الكتالوج.

## الدفعات والمبالغ

الموقع لديه دفعات تاريخية داخل `invoice.payments` ودفعات مستقلة في `customerPayments`. أضيف `legacy_invoice_id` لحفظ مصدر الدفعة القديمة مستقبلًا، مع بقاء الدفعات الجديدة على مستوى إجمالي حساب العميل. **لم تُنقل دفعات إلى ledger ولم تتغير أي مبالغ تاريخية في هذه المهمة.**

المعاينة تجمع صافي مديونية الفواتير غير الملغاة، وتطرح دفعاتها القديمة ودفعات الحساب مرة واحدة. لا تضيف خطة التقسيط كمديونية ثانية. الفاتورة الملغاة ودفعاتها التابعة لا تدخل الحساب. تكرار معرّف دفعة عبر المصدرين يتوقف للمراجعة.

Flutter يحافظ على القروش الصحيحة. `price` و`amount` في JSON يظلان كما وردا. التحويل إلى القروش يرفض دقة غير قابلة للتمثيل بدل قص الكسور. كميات الموقع الكسرية أو اختلاف جمع تقريب البنود عن إجمالي الفاتورة يظهر كـblocker؛ الملف الأصلي يبقى محفوظًا في staging ولا يتحول إلى كمية صحيحة أو مبلغ مختلف.

## الترقية المحلية v1 إلى v2

`CompatibilitySchema` تضيف أعمدة وجداول فقط. لا DROP، لا مسح للبيانات ولا إعادة كتابة لأرصدة العملاء. تبقى الأعمدة السابقة ومعرّفاتها ومبالغها والـoutbox والـcursor موجودة. تطبق الترقية داخل transaction، وتتحقق من وجود العمود قبل إضافته، ويمكن تكرار تشغيلها. `schemaVersion = 2` مرتبط بـMigrationStrategy صريح.

`web_document_staging` يحفظ ملف الموقع وتقرير المعاينة تحت `staging:<source_user_id>`. `WebCompatibilityRepository.stage` لا يكتب في العملاء أو الفواتير أو الدفعات أو ledger ولا يعلّم عمليات outbox بأنها متزامنة. لا يوجد زر استيراد يغير بيانات المستخدم؛ هذه واجهة برمجية تحضيرية للدمج التالي.

مثال للاستخدام داخل أدوات التطوير:

```dart
final repo = WebCompatibilityRepository(DatabaseService.to.db);
final preview = repo.preview(decodedBackup);
// Review preview.report and compare balances before any future adoption.
final stagedId = await repo.stage(
  sourceUserId: verifiedSourceUserId,
  sourceRevision: revision,
  input: decodedBackup,
);
```

هوية صاحب ملف backup قد لا تكون مضمنة داخله. يجب التحقق من مصدره عند الاستخدام؛ staging لا تدّعي إثبات ملكية الملف.

## ما يبقى من إضافات Flutter وما يحتاجه الموقع لاحقًا

| قدرة Flutter | قرار الدمج اللاحق |
|---|---|
| `workspaces`, owner/team boundaries | إنشاء ربط موثوق بين `auth.users.id` وworkspace بدل `default` العام، ثم إضافته للسيرفر والموقع |
| تخزين محلي علائقي، UUID، version/tombstone | الحفاظ عليه، وتجهيز مخطط سحابي إضافي في بيئة اختبار منفصلة |
| مبالغ بالقروش وخصم الفاتورة والبند | نقل المعنى للموقع قبل تمكين round-trip؛ لا تصدير يخفي الخصم داخل بند يدوي |
| ledger وعمليات عكس/تصحيح | بروتوكول أحداث محاسبية idempotent مع audit، لا last-write-wins للأموال |
| draft/posted/voided | توحيد دورة الحياة مع الموقع وإضافة اختبارات ترحيل للأرصدة |
| outbox وcursor وحالات الأخطاء | RPC فعلي يقبل العملية مرة واحدة، pull يطبق البيانات والـcursor في transaction واحدة |
| أقساط مفصّلة | جدول جدولة محلي محفوظ مع توحيد تاريخ أول استحقاق وتوزيع الكسور، من دون FIFO للدفعات افتراضيًا |
| صور/باركود/كتالوج الموقع | حقول وعقود مضافة الآن؛ شاشة المنتجات واستيراد الكتالوج تحتاجان ربطًا وظيفيًا لاحقًا |

بعض القدرات موصوفة أو معلنة كجداول في المشروع أكثر مما هي مكتملة وظيفيًا: shell يحتوي شاشات placeholder، النسخة الاحتياطية الحالية تصدر العملاء فقط، وAuth يستخدم `default` كمساحة مشتركة. لا تُعتبر نسخة جاهزة للإنتاج أو مزامنة آمنة بين عدة حسابات قبل معالجة ذلك. لم يُغيّر هذا العمل منطق الحسابات القائم أو يعلن اكتمال تلك الميزات.

## المزامنة والتشغيل

أزيل مسار المزامنة التجريبي الذي كان يكتب إلى `sync_inbox` ويقرأ `sync_outbox_events`، وهما غير موجودين في مرجع قاعدة الموقع. كان مسار pull يحرك المؤشر دون تطبيق أحداث. الآن لا توجد كتابة سحابية منه، لا acknowledgement للـoutbox، ولا رسالة نجاح مزامنة غير حقيقية. الواجهة تبين أن البيانات محفوظة على الجهاز وأن الربط بين المنصات قيد التجهيز.

المخطط النهائي يظل offline-first على الهاتف والكمبيوتر والويب، لكن **المزامنة الفعلية مؤجلة ضمن نطاق طلب توحيد البيانات الحالي**. بين جهازين غير متصلين لا تحدث مزامنة عبر الإنترنت؛ تنتظر الاتصال والتسوية. الخلفية والنسخ عند منتصف الليل best effort وتعوّض عند فتح التطبيق، وليست ضمان تشغيل أثناء إغلاقه.

## الدمج الفعلي بعد هذه المهمة

1. فرع وبيئة staging منفصلان مع نسخة اختبار مجهولة الهوية، ونسخة احتياطية موثقة قابلة للاستعادة.
2. حسم ربط الحساب وworkspace وعزل بيانات الجهاز، ثم إكمال المنتجات والإعدادات والفواتير والأقساط في المستودعات والواجهات.
3. بناء mapper مزدوج الاتجاه لكل الحقول الجديدة، مع مقارنة عدد الكيانات وأرصدة كل عميل على نسخ قديمة.
4. تصميم ترقية PostgreSQL إضافية، تدعم إصدار الموقع القديم والجديد أثناء الانتقال؛ لا تشغيل ملف `supabase_migration_relational.sql` القديم على الإنتاج تلقائيًا.
5. تطبيق idempotency ونسخ الأحداث وtombstones ومعالجة التعارض، ثم اختبارات جهازين أوفلاين/إعادة المحاولة/فقد الرد/انتهاء الجلسة.
6. ترقية الموقع بميزات Flutter الإضافية واختبار التوافق، ثم إطلاق تدريجي بعد مراجعة نتائج البيئة المنفصلة.

## التحقق في هذه الجلسة

- `python scripts/verify_web_alignment.py`: نجحت 4 اختبارات. تنفذ SQL الحقيقي في SQLite، وتقارن أعمدة جداول cache بالمرجع، وتجرب ترقية فيها بيانات قديمة وإعادة تطبيقها وتتحقق من بقاء الأموال والـoutbox والـcursor، وتفحص حدود قراءة الـadapter.
- أضيف `test/web_alignment_test.dart`: اختبارات round-trip، أرصدة، دفعات مكررة، دقة وكمية كسرية، صلاحيات account DTO، وترقية ملف SQLite v1 وإعادة فتحه عبر Drift وstaging معزول.
- Flutter/Dart SDK غير متاحين في بيئة التنفيذ؛ اختبارات Dart والتحليل والبناء لم تُشغل محليًا. لا يوجد APK أو Windows build أو web build منتج هنا.
- أضيف workflow للتحقق اليدوي/طلبات الدمج. يحل الاعتماديات في نسخة مؤقتة فقط مع `--enforce-lockfile`. لم يُعلن نجاح الـworkflow قبل تشغيله.
- لم يتغير `pubspec.yaml` أو `pubspec.lock` ولم تضاف مكتبات.

### ملاحظة التراجع

لا يلزم rollback للإنتاج لأن الإنتاج لم يتغير. عند اختبار app محليًا، احتفظ بنسخة مغلقة من ملف SQLite قبل الترقية. الرجوع إلى binary قديم مع `user_version=2` قد يرفض downgrade؛ استرجع نسخة الملف السابقة بدل حذف الأعمدة أو خفض الإصدار يدويًا. النسخ المُعلّقة تحت staging ليست دمجًا مع البيانات الأصلية.
