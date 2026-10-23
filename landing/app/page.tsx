import Image from 'next/image';
import Arrow from './components/arrow';

const features = [
  ['01', 'كل عميل، حسابه واضح', 'بيانات العميل وفواتيره ودفعاته ورصيده المتبقي قدامك في شاشة واحدة.'],
  ['02', 'فاتورة على قد شغلك', 'بيع نقدي أو آجل أو بالأقساط، مع بنود وأسعار ودفعة مقدمة وجدول استحقاقات.'],
  ['03', 'الأقساط تحت عينك', 'اعرف المستحق والقريب والمتأخر، والدفعات تخصم من أقدم استحقاق أولًا.'],
  ['04', 'كشف حساب مفهوم', 'تابع حركة الحساب بالتاريخ، واطبع أو صدّر كشف الحساب PDF بالعربي.'],
  ['05', 'شغلك معاك', 'واجهة تناسب الموبايل والكمبيوتر، وتجربة ويب تدخلها بموافقة من موبايلك.'],
  ['06', 'طباعة تناسب محلك', 'إعدادات للفواتير والشعار والطابعة، ومقاسات ورق A4 و58 و80 مم.'],
];
const faq = [
  ['إيه الفرق بين الموقع ونسخة الويب؟', 'الموقع بيعرّفك بالنوتة ويساعدك تختار النسخة المناسبة. نسخة الويب هي التطبيق نفسه لإدارة الحسابات، وتفتحها من زر «افتح النوتة Web».'],
  ['بدخل من الكمبيوتر إزاي؟', 'افتح نسخة الويب، وامسح QR بكاميرا الموبايل. التطبيق يطلب منك مقارنة كود التأكيد والموافقة قبل فتح حسابك على الكمبيوتر. يلزم إصدار موبايل يدعم ربط الأجهزة ونفس بيئة الحساب.'],
  ['هل نسخة المعاينة بتغيّر بياناتي الحالية؟', 'المعاينة مستقلة عن الموقع القديم. الربط التجريبي لا يرحّل حسابات العملاء أو يشغّل مزامنة دفتر الحسابات القديم.'],
  ['هل فيه نسخة Windows 32-bit؟', 'تطبيق Windows الأصلي متاح لمعمارية 64-bit عند نشر المثبّت. أجهزة 32-bit تستخدم نسخة الويب على متصفح مدعوم.'],
  ['فين روابط التحميل؟', 'روابط APK ومثبّت Windows تظهر بعد توقيع ملفات الإصدار ونشرها والتحقق منها. النسخة التجريبية لا تعرض روابط تحميل وهمية.'],
];

function Mark() { return <span className="brand"><Image src="/logo.png" alt="" width={42} height={42} /><b>النوتة<span>ElNota</span></b></span>; }

export default function Home() {
  return <>
    <div className="preview-bar">نسخة معاينة مستقلة <span>•</span> جرّب الشكل والتجربة قبل الإطلاق</div>
    <header className="nav wrap"><a href="/" aria-label="النوتة الرئيسية"><Mark /></a><nav aria-label="القائمة الرئيسية"><a href="#features">المميزات</a><a href="#how">إزاي تبدأ</a><a href="#downloads">التحميلات</a><a href="#faq">أسئلة شائعة</a></nav><a className="button small" href="/web">افتح النوتة Web <Arrow direction="diagonal" /></a></header>
    <main>
      <section className="hero wrap">
        <div className="hero-copy"><span className="eyebrow"><i /> نوتة شغلك، بشكل جديد</span><h1>حسابات أوضح.<br /><em>وشغل أريح.</em></h1><p>عملاءك، فواتيرك، واللي ليك واللي عليك.<br />كل تفاصيل شغلك في نوتة واحدة، سهلة ومنظمة.</p><div className="hero-actions"><div className="actions"><a className="button" href="/web">افتح نسخة الويب <Arrow /></a><a className="button secondary" href="#downloads">اختار نسختك <Arrow direction="down" /></a></div><a className="button demo-button" href="/demo">جرب حساب ديمو <Arrow /></a></div><div className="hero-notes"><span>✓ عربي من أول شاشة</span><span>✓ للموبايل والكمبيوتر</span><span>✓ نقدي، آجل، وأقساط</span></div></div>
        <div className="hero-visual"><div className="floating-note"><span className="note-icon">✓</span><div><b>كل دفعة في مكانها</b><small>ورصيد عميلك واضح دايمًا</small></div></div><div className="browser-card"><div className="browser-top"><span>elnota · مساحة شغلك</span><div><i /><i /><i /></div></div><Image className="dashboard-image" src="/dashboard.png" alt="معاينة واجهة النوتة العربية: ملخص المستحقات والعملاء وآخر العمليات وحركة التحصيل" width={1586} height={992} priority /></div><span className="visual-caption">نظرة واحدة، وتبقى عارف حساباتك واقفة فين.</span></div>
      </section>
      <section className="trust wrap"><span>مساحة واحدة لكل تفاصيل شغلك</span><div><b>العملاء</b><i>✦</i><b>الفواتير</b><i>✦</i><b>الدفعات</b><i>✦</i><b>الأقساط</b><i>✦</i><b>كشف الحساب</b></div></section>
      <section className="section wrap" id="features"><div className="section-heading"><span className="eyebrow">تفاصيل أقل تتوه منك</span><h2>ركّز في شغلك.<br />وسيّب الحسابات للنوتة.</h2><p>أدوات واضحة للي بتحتاجه كل يوم، من أول فاتورة لآخر دفعة.</p></div><div className="feature-grid">{features.map(([number,title,text])=><article className="feature" key={number}><span>{number}</span><h3>{title}</h3><p>{text}</p></article>)}</div></section>
      <section className="account-section"><div className="wrap account-grid"><div><span className="eyebrow">الصورة كاملة، من غير لف</span><h2>افتح حساب العميل.<br />هتلاقي كل إجاباتك.</h2><p>باع بكام؟ دفع كام؟ فاضل عليه إيه؟<br />الفواتير والدفعات والاستحقاقات جنب بعض، عشان كل تعامل يبقى واضح.</p><a className="text-link" href="/web">شوف تجربة الويب <Arrow /></a></div><div className="image-panel"><Image src="/account.png" alt="واجهة حساب العميل موضحة إجمالي الفواتير والمدفوع والمتبقي والأقساط" width={1586} height={992} /></div></div></section>
      <section className="section wrap" id="how"><div className="section-heading centered"><span className="eyebrow">من الموبايل للكمبيوتر</span><h2>افتح الويب في ٣ خطوات.</h2><p>الدخول بيتم بموافقتك من التطبيق، من غير مشاركة كلمة السر.</p></div><div className="steps"><article><b>١</b><h3>افتح نسخة الويب</h3><p>من الكمبيوتر أو المتصفح، افتح شاشة ربط الأجهزة.</p></article><article><b>٢</b><h3>امسح رمز QR</h3><p>استخدم كاميرا موبايلك لفتح طلب الربط في التطبيق.</p></article><article><b>٣</b><h3>قارن الكود ووافق</h3><p>اتأكد من كود التأكيد، ووافق على الجهاز اللي قدامك.</p></article></div><div className="center"><a className="button" href="/web">جرّب نسخة الويب <Arrow direction="diagonal" /></a></div></section>
      <section className="downloads-section" id="downloads"><div className="wrap"><div className="section-heading centered"><span className="eyebrow">النوتة على جهازك</span><h2>اختار اللي يريحك في الشغل.</h2><p>على الموبايل، الكمبيوتر، أو من المتصفح.</p></div><div className="download-grid"><article className="download"><span className="platform">◉</span><h3>Android</h3><p>حساباتك معاك، أينما كنت.</p><span className="pending">APK قيد تجهيز الإصدار</span><small>التحميل يظهر بعد توقيع الإصدار والتحقق منه.</small></article><article className="download"><span className="platform">⊞</span><h3>Windows</h3><p>مساحة أكبر لشغل يومك.</p><span className="pending">مثبّت 64-bit قيد التجهيز</span><small>لأجهزة 32-bit: استخدم نسخة الويب.</small></article><article className="download featured"><span className="platform">◎</span><span className="tag">من غير تثبيت</span><h3>نسخة الويب</h3><p>افتح المتصفح، واربط موبايلك.</p><a className="button" href="/web">افتح النوتة Web <Arrow /></a><small>حالة الربط التجريبي موضحة في صفحة الويب.</small></article></div></div></section>
      <section className="section wrap faq-section" id="faq"><div className="section-heading"><span className="eyebrow">قبل ما تبدأ</span><h2>أسئلة على بالك؟</h2><p>دي إجابات تساعدك تختار وتبدأ.</p></div><div className="faq-list">{faq.map(([q,a])=><details key={q}><summary>{q}<span>+</span></summary><p>{a}</p></details>)}</div></section>
      <section className="wrap final-cta"><div><span>دفتر جديد لشغل مرتب</span><h2>خلّي كل حساب، في مكانه.</h2></div><a className="button white" href="/web">افتح النوتة <Arrow /></a></section>
    </main>
    <footer className="wrap"><Mark /><p>النوتة — شغلك منظم، وحساباتك واضحة.</p><a href="/privacy">الخصوصية</a><span>© {new Date().getFullYear()} النوتة</span></footer>
  </>;
}
