'use client';

import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui/button';
import { LanguageSwitcher } from '@/components/language-switcher';
import Link from 'next/link';

export default function HomePage() {
  const t = useTranslations('common');

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-blue-50 via-white to-orange-50 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900">
      <div className="absolute top-4 right-4">
        <LanguageSwitcher />
      </div>
      
      <div className="text-center space-y-8 px-4 max-w-2xl">
        <div className="space-y-2">
          <h1 className="text-6xl font-bold tracking-tight bg-gradient-to-r from-blue-600 to-orange-600 bg-clip-text text-transparent">
            {t('appName')}
          </h1>
          <p className="text-2xl text-gray-600 dark:text-gray-300 font-light">
            {t('slogan')}
          </p>
        </div>

        <div className="flex flex-col sm:flex-row gap-4 justify-center items-center mt-12">
          <Button asChild size="lg" className="min-w-48 text-lg">
            <Link href="/login">{t('getStarted')}</Link>
          </Button>
        </div>

        <div className="text-sm text-gray-500 dark:text-gray-400 mt-8">
          <p>🌍 Connect with locals and explore the world together</p>
        </div>
      </div>
    </div>
  );
}
