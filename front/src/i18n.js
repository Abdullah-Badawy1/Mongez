import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import translationEN from './locales/en/translation.json';
import translationAR from './locales/ar/translation.json';

// الموارد المتاحة
const resources = {
  en: {
    translation: translationEN
  },
  ar: {
    translation: translationAR
  }
};

i18n
  .use(initReactI18next) // يمرر i18n إلى react-i18next
  .init({
    resources,
    lng: 'en', // اللغة الافتراضية
    fallbackLng: 'en', // اللغة الاحتياطية
    interpolation: {
      escapeValue: false // React يقوم بتأمين النصوص تلقائياً
    },
    react: {
      useSuspense: false // لتعطيل suspense إذا أردت (اختياري)
    }
  });

export default i18n;