// إضافة المتغيرات العامة لجميع القوالب
const defaultContext = {
    siteName: process.env.SITE_NAME,
    supportEmail: process.env.SUPPORT_EMAIL,
    companyAddress: process.env.COMPANY_ADDRESS,
    currentYear: new Date().getFullYear(),
    frontendUrl: process.env.FRONTEND_URL
};

// دمج المتغيرات العامة مع سياق القالب
mailOptions.context = {
    ...defaultContext,
    ...mailOptions.context
};