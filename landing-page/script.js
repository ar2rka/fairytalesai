/**
 * LANDING PAGE JAVASCRIPT
 * Conversion Optimization & Analytics Tracking
 * 
 * Features:
 * - Scroll depth tracking
 * - CTA click tracking
 * - Form abandonment tracking
 * - Exit intent popup
 * - Scroll reveal animations
 * - A/B testing framework ready
 * - Heatmap integration ready
 */

(function() {
    'use strict';

    // ============================================
    // ANALYTICS & TRACKING
    // ============================================

    /**
     * Track events for analytics
     * Replace with your analytics service (Google Analytics, Mixpanel, etc.)
     */
    function trackEvent(eventName, eventData = {}) {
        // Example for Google Analytics 4:
        // if (typeof gtag !== 'undefined') {
        //     gtag('event', eventName, eventData);
        // }
        
        // Example for Mixpanel:
        // if (typeof mixpanel !== 'undefined') {
        //     mixpanel.track(eventName, eventData);
        // }
        
        // Fallback to console and window.analytics
        console.log('Analytics Event:', eventName, eventData);
        if (window.analytics && typeof window.analytics.track === 'function') {
            window.analytics.track(eventName, eventData);
        }
    }

    /**
     * Track scroll depth
     * Psychological principle: Measure engagement
     */
    function initScrollDepthTracking() {
        const milestones = [25, 50, 75, 90, 100];
        const tracked = new Set();
        let maxScroll = 0;

        function checkScrollDepth() {
            const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
            const docHeight = document.documentElement.scrollHeight - window.innerHeight;
            const scrollPercent = Math.round((scrollTop / docHeight) * 100);

            if (scrollPercent > maxScroll) {
                maxScroll = scrollPercent;
                
                milestones.forEach(milestone => {
                    if (scrollPercent >= milestone && !tracked.has(milestone)) {
                        tracked.add(milestone);
                        trackEvent('scroll_depth', {
                            depth: milestone,
                            timestamp: Date.now()
                        });
                    }
                });
            }
        }

        // Throttle scroll events for performance
        let ticking = false;
        window.addEventListener('scroll', function() {
            if (!ticking) {
                window.requestAnimationFrame(function() {
                    checkScrollDepth();
                    ticking = false;
                });
                ticking = true;
            }
        }, { passive: true });
    }

    /**
     * Track CTA clicks
     * Psychological principle: Measure conversion intent
     */
    function initCTATracking() {
        const ctaButtons = document.querySelectorAll('a[href="#signup"], .btn-primary, .btn-cta-mobile');
        
        ctaButtons.forEach((button, index) => {
            button.addEventListener('click', function(e) {
                const ctaText = this.textContent.trim();
                const ctaLocation = this.closest('section')?.id || 'unknown';
                
                trackEvent('cta_click', {
                    cta_text: ctaText,
                    cta_location: ctaLocation,
                    cta_index: index,
                    timestamp: Date.now()
                });
            });
        });
    }

    /**
     * Track form abandonment
     * Psychological principle: Identify friction points
     */
    function initFormAbandonmentTracking() {
        const form = document.getElementById('signupForm');
        if (!form) return;

        const emailInput = form.querySelector('input[type="email"]');
        let formStarted = false;
        let formFocused = false;

        // Track when user starts filling form
        emailInput.addEventListener('focus', function() {
            if (!formStarted) {
                formStarted = true;
                formFocused = true;
                trackEvent('form_started', {
                    timestamp: Date.now()
                });
            }
        });

        // Track when user leaves form without submitting
        emailInput.addEventListener('blur', function() {
            if (formStarted && formFocused && !form.querySelector('input[type="email"]').value) {
                trackEvent('form_abandoned', {
                    timestamp: Date.now()
                });
            }
        });

        // Track successful form submission
        form.addEventListener('submit', function(e) {
            e.preventDefault(); // Prevent default for demo - remove in production
            
            const email = emailInput.value;
            
            trackEvent('form_submitted', {
                email: email, // Hash this in production for privacy
                timestamp: Date.now()
            });

            // Show success message or redirect
            showFormSuccess();
        });
    }

    /**
     * Show form success message
     */
    function showFormSuccess() {
        const form = document.getElementById('signupForm');
        const formGroup = form.querySelector('.form-group');
        const submitButton = form.querySelector('button[type="submit"]');
        
        // Create success message
        const successMessage = document.createElement('div');
        successMessage.className = 'form-success';
        successMessage.style.cssText = `
            background: #2ECC71;
            color: white;
            padding: 1rem;
            border-radius: 8px;
            margin-bottom: 1rem;
            text-align: center;
            animation: fadeIn 0.3s ease;
        `;
        successMessage.textContent = '✨ Success! Check your email to get started.';
        
        form.insertBefore(successMessage, formGroup);
        
        // Disable form
        submitButton.disabled = true;
        submitButton.textContent = 'Check Your Email!';
        
        // In production, redirect to signup page or show next step
        // window.location.href = '/signup?email=' + encodeURIComponent(email);
    }

    // ============================================
    // EXIT INTENT POPUP
    // ============================================

    /**
     * Exit intent popup
     * Psychological principle: Scarcity & FOMO
     */
    function initExitIntentPopup() {
        const popup = document.getElementById('exitPopup');
        const closeBtn = document.getElementById('exitPopupClose');
        const dismissBtn = document.getElementById('exitPopupDismiss');
        let shown = false;

        // Check if popup was already shown in this session
        if (sessionStorage.getItem('exitPopupShown') === 'true') {
            return;
        }

        // Detect mouse leaving viewport (exit intent)
        document.addEventListener('mouseleave', function(e) {
            if (e.clientY < 0 && !shown) {
                showExitPopup();
            }
        });

        // Close popup handlers
        if (closeBtn) {
            closeBtn.addEventListener('click', hideExitPopup);
        }

        if (dismissBtn) {
            dismissBtn.addEventListener('click', function() {
                hideExitPopup();
                trackEvent('exit_popup_dismissed', {
                    timestamp: Date.now()
                });
            });
        }

        // Close on background click
        popup.addEventListener('click', function(e) {
            if (e.target === popup) {
                hideExitPopup();
            }
        });

        function showExitPopup() {
            shown = true;
            popup.classList.add('active');
            document.body.style.overflow = 'hidden';
            
            trackEvent('exit_popup_shown', {
                timestamp: Date.now()
            });
        }

        function hideExitPopup() {
            popup.classList.remove('active');
            document.body.style.overflow = '';
            sessionStorage.setItem('exitPopupShown', 'true');
        }
    }

    // ============================================
    // SCROLL REVEAL ANIMATIONS
    // ============================================

    /**
     * Scroll reveal animations
     * Psychological principle: Visual hierarchy & engagement
     */
    function initScrollReveal() {
        const revealElements = document.querySelectorAll('.problem-card, .step-card, .feature-card, .testimonial-card, .trust-item');
        
        // Add scroll-reveal class to elements
        revealElements.forEach(el => {
            el.classList.add('scroll-reveal');
        });

        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver(function(entries) {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('revealed');
                    observer.unobserve(entry.target);
                }
            });
        }, observerOptions);

        revealElements.forEach(el => {
            observer.observe(el);
        });
    }

    // ============================================
    // STICKY MOBILE CTA
    // ============================================

    /**
     * Show/hide sticky mobile CTA based on scroll position
     */
    function initStickyMobileCTA() {
        const stickyCTA = document.getElementById('stickyCtaMobile');
        if (!stickyCTA) return;

        const heroSection = document.getElementById('hero');
        const heroBottom = heroSection ? heroSection.offsetHeight : 0;
        let lastScrollY = window.scrollY;

        function handleScroll() {
            const currentScrollY = window.scrollY;
            
            // Show sticky CTA after scrolling past hero section
            if (currentScrollY > heroBottom && currentScrollY > lastScrollY) {
                stickyCTA.style.display = 'block';
            } else if (currentScrollY < heroBottom || currentScrollY < lastScrollY) {
                stickyCTA.style.display = 'none';
            }
            
            lastScrollY = currentScrollY;
        }

        // Throttle scroll events
        let ticking = false;
        window.addEventListener('scroll', function() {
            if (!ticking) {
                window.requestAnimationFrame(function() {
                    handleScroll();
                    ticking = false;
                });
                ticking = true;
            }
        }, { passive: true });
    }

    // ============================================
    // SMOOTH SCROLLING FOR ANCHOR LINKS
    // ============================================

    /**
     * Smooth scroll to anchor links
     */
    function initSmoothScroll() {
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function(e) {
                const href = this.getAttribute('href');
                if (href === '#') return;
                
                const target = document.querySelector(href);
                if (target) {
                    e.preventDefault();
                    const headerOffset = 80;
                    const elementPosition = target.getBoundingClientRect().top;
                    const offsetPosition = elementPosition + window.pageYOffset - headerOffset;

                    window.scrollTo({
                        top: offsetPosition,
                        behavior: 'smooth'
                    });
                }
            });
        });
    }

    // ============================================
    // REAL-TIME ACTIVITY INDICATOR
    // ============================================

    /**
     * Update real-time activity indicator
     * Psychological principle: Social proof
     */
    function initRealTimeActivity() {
        const activityText = document.querySelector('.activity-text');
        if (!activityText) return;

        function updateActivity() {
            updateActivityWithLanguage();
        }

        // Update every 8-15 seconds
        function scheduleUpdate() {
            const delay = Math.random() * 7000 + 8000; // 8-15 seconds
            setTimeout(() => {
                updateActivity();
                scheduleUpdate();
            }, delay);
        }

        // Initial update after page load
        setTimeout(updateActivity, 3000);
        scheduleUpdate();
    }

    // ============================================
    // PERFORMANCE OPTIMIZATION
    // ============================================

    /**
     * Lazy load images below the fold
     */
    function initLazyLoading() {
        if ('IntersectionObserver' in window) {
            const imageObserver = new IntersectionObserver((entries, observer) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        const img = entry.target;
                        if (img.dataset.src) {
                            img.src = img.dataset.src;
                            img.removeAttribute('data-src');
                        }
                        observer.unobserve(img);
                    }
                });
            });

            document.querySelectorAll('img[data-src]').forEach(img => {
                imageObserver.observe(img);
            });
        }
    }

    /**
     * Preload critical resources
     */
    function preloadCriticalResources() {
        // Preload fonts
        const fontLink = document.createElement('link');
        fontLink.rel = 'preload';
        fontLink.as = 'font';
        fontLink.type = 'font/woff2';
        fontLink.crossOrigin = 'anonymous';
        // Add font URLs if needed
    }

    // ============================================
    // LANGUAGE SWITCHER & TRANSLATIONS
    // ============================================

    /**
     * Translations object
     */
    const translations = {
        en: {
            hero: {
                headline: 'Magical Bedtime Stories',
                headlineHighlight: 'Starring Your Child',
                subheadline: 'Personalized AI adventures that make your child the hero. Create magical moments every night with stories made just for them.',
                cta: 'Create Your First Story Free',
                ctaNote: '✨ No credit card required • Cancel anytime',
                activity: 'Anna from Limassol just created a story'
            },
            problem: {
                headline: 'You\'re Not Alone',
                subheadline: 'Every parent faces these bedtime challenges:',
                card1: {
                    title: 'Tired of the Same Stories',
                    text: 'Reading the same books every night? Your child deserves fresh adventures that spark their imagination.'
                },
                card2: {
                    title: 'Struggling to Find the Right Story',
                    text: 'Want stories that match your child\'s interests, age, and values? Finding the perfect book is exhausting.'
                },
                card3: {
                    title: 'Bedtime Battles',
                    text: 'Turning bedtime into a peaceful, magical experience shouldn\'t be a struggle. You deserve better.'
                }
            },
            solution: {
                headline: 'How It Works',
                subheadline: 'Create magical stories in seconds',
                step1: {
                    title: 'Add Your Child\'s Profile',
                    text: 'Tell us your child\'s name, age, and interests. We\'ll create stories perfectly tailored to them.'
                },
                step2: {
                    title: 'Choose Story Parameters',
                    text: 'Select story length, mood, characters, and themes. Every story is customizable to your preferences.'
                },
                step3: {
                    title: 'Generate in Seconds',
                    text: 'Our AI creates a unique, personalized story starring your child. Watch the magic happen instantly.'
                },
                step4: {
                    title: 'Enjoy Reading Together',
                    text: 'Share magical moments as you read stories where your child is the hero. Create memories that last.'
                }
            },
            features: {
                headline: 'Why Parents Love Us',
                cta: 'Start Creating Magical Stories',
                card1: {
                    title: 'Stories That Grow With Your Child',
                    text: 'As your child develops, our stories adapt. From simple adventures to complex narratives, we match their growth.'
                },
                card2: {
                    title: 'Fairy Tail Therapy',
                    text: 'Our stories incorporate therapeutic elements that help children process emotions, build resilience, and develop emotional intelligence through engaging narratives.'
                },
                card3: {
                    title: 'Your Child as the Main Hero',
                    text: 'Every story features your child as the protagonist. They\'ll love seeing themselves in magical adventures.'
                },
                card4: {
                    title: 'New Adventure Every Night',
                    text: 'Never run out of stories. Generate unlimited unique adventures tailored to your child\'s interests.'
                },
                card5: {
                    title: 'Customizable Themes & Values',
                    text: 'Choose stories that teach kindness, bravery, friendship, or any values important to your family.'
                },
                card6: {
                    title: 'Audio Narration Available',
                    text: 'Let our AI narrator read stories aloud. Perfect for busy parents or when your voice needs a break.'
                }
            },
            cta: {
                headline: 'Ready to Create Magic?',
                subheadline: 'Join thousands of parents creating unforgettable bedtime moments',
                emailPlaceholder: 'Enter your email',
                submit: 'Create My Child\'s First Story Free',
                formNote: '✨ No credit card required • Start in 30 seconds • Cancel anytime',
                badge1: '🔒 Secure',
                badge2: '🛡️ Safe',
                badge3: '✅ Guaranteed'
            },
            footer: {
                privacy: 'Privacy',
                terms: 'Terms',
                safety: 'Safety',
                copyright: '© 2024 Magical Stories. All rights reserved.'
            },
            popup: {
                title: 'Wait! Don\'t Miss Out',
                text: 'Get your first story absolutely free - no credit card required!',
                cta: 'Yes, I Want My Free Story',
                dismiss: 'No thanks, I\'ll pass'
            },
            mobile: {
                cta: 'Create Free Story'
            }
        },
        ru: {
            hero: {
                headline: 'Волшебные сказки на ночь',
                headlineHighlight: 'С вашим ребенком в главной роли',
                subheadline: 'Персонализированные AI-приключения, где ваш ребенок — главный герой. Создавайте волшебные моменты каждую ночь с историями, созданными специально для него.',
                cta: 'Создать первую историю бесплатно',
                ctaNote: '✨ Не требуется карта • Отменить можно в любой момент',
                activity: 'Анна из Лимассола только что создала историю'
            },
            problem: {
                headline: 'Вы не одиноки',
                subheadline: 'Вот с какими проблемами перед сном сталкивается каждый родитель:',
                card1: {
                    title: 'Устали от одних и тех же сюжетов?',
                    text: 'Перечитываете одни и те же книги каждую ночь? Ваш ребенок заслуживает свежих, захватывающих приключений, которые действительно разжигают его воображение.'
                },
                card2: {
                    title: 'Сложно найти подходящую книгу?',
                    text: 'Вам нужны истории, которые идеально соответствуют интересам, возрасту и ценностям вашего ребенка? Поиск идеальной книги может быть утомительным.'
                },
                card3: {
                    title: '«Битвы» перед сном',
                    text: 'Время укладывания не должно превращаться в борьбу. Вы заслуживаете того, чтобы сделать его мирным и волшебным ритуалом.'
                }
            },
            solution: {
                headline: 'Как это работает',
                subheadline: 'Создайте волшебную историю за считанные секунды',
                step1: {
                    title: 'Создайте профиль ребенка',
                    text: 'Укажите нам имя, возраст и интересы вашего ребенка. Мы будем генерировать истории, идеально настроенные под него.'
                },
                step2: {
                    title: 'Выберите параметры',
                    text: 'Определите длину, настроение, персонажей и темы истории. Вы контролируете каждую деталь.'
                },
                step3: {
                    title: 'Генерация за мгновение',
                    text: 'Наш AI создаст уникальную, персонализированную историю с вашим ребенком в главной роли. Наблюдайте, как магия происходит мгновенно.'
                },
                step4: {
                    title: 'Наслаждайтесь совместным чтением',
                    text: 'Разделите волшебство, читая истории, где ваш ребенок — настоящий герой. Создавайте воспоминания, которые останутся с ним навсегда.'
                }
            },
            features: {
                headline: 'Почему родители выбирают нас',
                cta: 'Начать создавать волшебные истории',
                card1: {
                    title: 'Истории, которые растут вместе с ребенком',
                    text: 'По мере развития вашего ребенка, наши истории адаптируются. От простых приключений до сложных сюжетов — мы соответствуем их росту.'
                },
                card2: {
                    title: 'Элементы сказкотерапии',
                    text: 'Наши истории содержат терапевтические элементы, помогающие детям прорабатывать эмоции, развивать устойчивость и эмоциональный интеллект через увлекательные повествования.'
                },
                card3: {
                    title: 'Ваш ребенок — главный герой',
                    text: 'В каждой истории ваш ребенок является ключевым персонажем. Им безумно понравится видеть себя участником волшебных приключений.'
                },
                card4: {
                    title: 'Новое приключение каждую ночь',
                    text: 'Истории никогда не закончатся. Генерируйте неограниченное количество уникальных приключений, адаптированных под текущие интересы ребенка.'
                },
                card5: {
                    title: 'Настройка темы и ценностей',
                    text: 'Выбирайте истории, которые ненавязчиво учат доброте, храбрости, дружбе или любым другим ценностям, важным для вашей семьи.'
                },
                card6: {
                    title: 'Доступна аудиоверсия',
                    text: 'Позвольте нашему AI-рассказчику прочитать историю вслух. Идеально для занятых родителей или если вашему голосу нужен небольшой перерыв.'
                }
            },
            cta: {
                headline: 'Готовы создать магию?',
                subheadline: 'Присоединяйтесь к тысячам родителей, создающих незабываемые моменты перед сном',
                emailPlaceholder: 'Введите ваш email',
                submit: 'Создать первую историю моего ребенка бесплатно',
                formNote: '✨ Не требуется карта • Начните за 30 секунд • Отменить можно в любой момент',
                badge1: '🔒 Безопасно',
                badge2: '🛡️ Защищено',
                badge3: '✅ Гарантировано'
            },
            footer: {
                privacy: 'Конфиденциальность',
                terms: 'Условия',
                safety: 'Безопасность',
                copyright: '© 2024 Magical Stories. Все права защищены.'
            },
            popup: {
                title: 'Подождите! Не упустите шанс',
                text: 'Получите вашу первую историю совершенно бесплатно — без привязки банковской карты!',
                cta: 'Да, я хочу мою бесплатную историю',
                dismiss: 'Нет, спасибо, я откажусь'
            },
            mobile: {
                cta: 'Создать бесплатную историю'
            }
        }
    };

    /**
     * Get current language from localStorage or default to 'en'
     */
    function getCurrentLanguage() {
        return localStorage.getItem('language') || 'en';
    }

    /**
     * Set current language in localStorage
     */
    function setCurrentLanguage(lang) {
        localStorage.setItem('language', lang);
    }

    /**
     * Translate text content
     */
    function translateText(element, key, lang) {
        const keys = key.split('.');
        let value = translations[lang];
        
        for (const k of keys) {
            value = value[k];
            if (!value) return;
        }
        
        if (typeof value === 'string') {
            element.textContent = value;
        }
    }

    /**
     * Translate HTML content with nested structure
     */
    function translateHTML(element, key, lang) {
        const keys = key.split('.');
        let value = translations[lang];
        
        for (const k of keys) {
            value = value[k];
            if (!value) return;
        }
        
        if (typeof value === 'string') {
            element.textContent = value;
        }
    }

    /**
     * Translate placeholder attribute
     */
    function translatePlaceholder(element, key, lang) {
        const keys = key.split('.');
        let value = translations[lang];
        
        for (const k of keys) {
            value = value[k];
            if (!value) return;
        }
        
        if (typeof value === 'string') {
            element.placeholder = value;
        }
    }

    /**
     * SEO meta tags translations
     */
    const seoMetaTags = {
        en: {
            title: 'Magical Bedtime Stories Starring Your Child | AI Story Generator',
            description: 'Create personalized AI bedtime stories starring your child. Magical adventures that make bedtime the best time of day. Generate unlimited unique stories tailored to your child\'s interests, age, and values.',
            ogTitle: 'Magical Bedtime Stories Starring Your Child | AI Story Generator',
            ogDescription: 'Create personalized AI bedtime stories starring your child. Magical adventures that make bedtime the best time of day. Generate unlimited unique stories tailored to your child\'s interests.',
            twitterTitle: 'Magical Bedtime Stories Starring Your Child',
            twitterDescription: 'Create personalized AI bedtime stories starring your child. Magical adventures that make bedtime the best time of day.'
        },
        ru: {
            title: 'Волшебные сказки на ночь с вашим ребенком в главной роли | Генератор историй',
            description: 'Создавайте персонализированные AI-приключения, где ваш ребенок — главный герой. Генерируйте неограниченное количество уникальных историй, адаптированных под интересы, возраст и ценности вашего ребенка.',
            ogTitle: 'Волшебные сказки на ночь с вашим ребенком в главной роли | Генератор историй',
            ogDescription: 'Создавайте персонализированные AI-приключения, где ваш ребенок — главный герой. Генерируйте неограниченное количество уникальных историй, адаптированных под интересы вашего ребенка.',
            twitterTitle: 'Волшебные сказки на ночь с вашим ребенком в главной роли',
            twitterDescription: 'Создавайте персонализированные AI-приключения, где ваш ребенок — главный герой. Генерируйте уникальные истории для вашего ребенка.'
        }
    };

    /**
     * Update SEO meta tags based on language
     */
    function updateSEOMetaTags(lang) {
        const meta = seoMetaTags[lang] || seoMetaTags.en;
        
        // Update title
        document.title = meta.title;
        const titleMeta = document.querySelector('meta[name="title"]');
        if (titleMeta) titleMeta.setAttribute('content', meta.title);
        
        // Update description
        const descMeta = document.querySelector('meta[name="description"]');
        if (descMeta) descMeta.setAttribute('content', meta.description);
        
        // Update Open Graph tags
        const ogTitle = document.querySelector('meta[property="og:title"]');
        if (ogTitle) ogTitle.setAttribute('content', meta.ogTitle);
        
        const ogDesc = document.querySelector('meta[property="og:description"]');
        if (ogDesc) ogDesc.setAttribute('content', meta.ogDescription);
        
        const ogLocale = document.querySelector('meta[property="og:locale"]');
        if (ogLocale) ogLocale.setAttribute('content', lang === 'ru' ? 'ru_RU' : 'en_US');
        
        // Update Twitter tags
        const twitterTitle = document.querySelector('meta[name="twitter:title"]');
        if (twitterTitle) twitterTitle.setAttribute('content', meta.twitterTitle);
        
        const twitterDesc = document.querySelector('meta[name="twitter:description"]');
        if (twitterDesc) twitterDesc.setAttribute('content', meta.twitterDescription);
        
        // Update language meta tag
        const langMeta = document.querySelector('meta[name="language"]');
        if (langMeta) langMeta.setAttribute('content', lang === 'ru' ? 'Russian' : 'English');
    }

    /**
     * Apply translations to all elements
     */
    function applyTranslations(lang) {
        // Update HTML lang attribute
        document.documentElement.lang = lang;
        
        // Update SEO meta tags
        updateSEOMetaTags(lang);
        
        // Special handling for hero headline with nested span
        const heroHeadline = document.querySelector('.hero-headline[data-i18n="hero.headline"]');
        const heroHighlight = document.querySelector('.hero-headline .highlight[data-i18n="hero.headlineHighlight"]');
        
        if (heroHeadline && heroHighlight) {
            // Translate main headline text (everything except the span)
            const headlineKeys = 'hero.headline'.split('.');
            const highlightKeys = 'hero.headlineHighlight'.split('.');
            let headlineValue = translations[lang];
            let highlightValue = translations[lang];
            
            for (const k of headlineKeys) {
                headlineValue = headlineValue[k];
            }
            for (const k of highlightKeys) {
                highlightValue = highlightValue[k];
            }
            
            if (headlineValue && highlightValue) {
                // Set the text content of the h1, preserving the span structure
                const tempDiv = document.createElement('div');
                tempDiv.innerHTML = headlineValue + '<br><span class="highlight">' + highlightValue + '</span>';
                heroHeadline.innerHTML = tempDiv.innerHTML;
            }
        }
        
        // Translate all elements with data-i18n attribute (skip hero headline as it's handled above)
        document.querySelectorAll('[data-i18n]').forEach(element => {
            const key = element.getAttribute('data-i18n');
            // Skip hero headline parent as it's handled above
            if (key === 'hero.headline' && element.classList.contains('hero-headline')) return;
            // Skip highlight span as it's handled above
            if (key === 'hero.headlineHighlight' && element.classList.contains('highlight')) return;
            translateHTML(element, key, lang);
        });
        
        // Translate placeholder attributes
        document.querySelectorAll('[data-i18n-placeholder]').forEach(element => {
            const key = element.getAttribute('data-i18n-placeholder');
            translatePlaceholder(element, key, lang);
        });
        
        // Update language button text
        const langBtn = document.getElementById('langBtn');
        if (langBtn) {
            langBtn.textContent = lang === 'en' ? 'RU' : 'EN';
        }
        
        // Update activity text with Russian names/locations when in Russian
        if (lang === 'ru') {
            const activityText = document.querySelector('.activity-text');
            if (activityText) {
                const russianNames = ['Анна', 'Мария', 'Елена', 'Ольга', 'Татьяна', 'Ирина', 'Наталья', 'Светлана'];
                const russianLocations = ['Москва', 'Санкт-Петербург', 'Киев', 'Минск', 'Алматы', 'Новосибирск', 'Екатеринбург', 'Казань'];
                const name = russianNames[Math.floor(Math.random() * russianNames.length)];
                const location = russianLocations[Math.floor(Math.random() * russianLocations.length)];
                activityText.textContent = `${name} из ${location} только что создала историю`;
            }
        }
    }

    /**
     * Initialize language switcher
     */
    function initLanguageSwitcher() {
        const langBtn = document.getElementById('langBtn');
        if (!langBtn) return;
        
        // Load saved language preference
        const currentLang = getCurrentLanguage();
        applyTranslations(currentLang);
        
        // Handle language switch
        langBtn.addEventListener('click', function() {
            const currentLang = getCurrentLanguage();
            const newLang = currentLang === 'en' ? 'ru' : 'en';
            setCurrentLanguage(newLang);
            applyTranslations(newLang);
            
            // Update activity text immediately
            if (newLang === 'ru') {
                const activityText = document.querySelector('.activity-text');
                if (activityText) {
                    const russianNames = ['Анна', 'Мария', 'Елена', 'Ольга', 'Татьяна', 'Ирина', 'Наталья', 'Светлана'];
                    const russianLocations = ['Москва', 'Санкт-Петербург', 'Киев', 'Минск', 'Алматы', 'Новосибирск', 'Екатеринбург', 'Казань'];
                    const name = russianNames[Math.floor(Math.random() * russianNames.length)];
                    const location = russianLocations[Math.floor(Math.random() * russianLocations.length)];
                    activityText.textContent = `${name} из ${location} только что создала историю`;
                }
            }
            
            trackEvent('language_switched', {
                from: currentLang,
                to: newLang,
                timestamp: Date.now()
            });
        });
    }

    /**
     * Update real-time activity with language support
     */
    function updateActivityWithLanguage() {
        const activityText = document.querySelector('.activity-text');
        if (!activityText) return;

        const currentLang = getCurrentLanguage();
        
        if (currentLang === 'ru') {
            const russianNames = ['Анна', 'Мария', 'Елена', 'Ольга', 'Татьяна', 'Ирина', 'Наталья', 'Светлана'];
            const russianLocations = ['Москва', 'Санкт-Петербург', 'Киев', 'Минск', 'Алматы', 'Новосибирск', 'Екатеринбург', 'Казань'];
            const name = russianNames[Math.floor(Math.random() * russianNames.length)];
            const location = russianLocations[Math.floor(Math.random() * russianLocations.length)];
            activityText.textContent = `${name} из ${location} только что создала историю`;
        } else {
            const locations = [
                'Limassol', 'London', 'San Francisco', 'Barcelona', 'New York',
                'Toronto', 'Sydney', 'Berlin', 'Paris', 'Tokyo'
            ];
            const names = [
                'Anna', 'Sarah', 'James', 'Emma', 'Michael', 'Sophia',
                'David', 'Olivia', 'Daniel', 'Isabella'
            ];
            const name = names[Math.floor(Math.random() * names.length)];
            const location = locations[Math.floor(Math.random() * locations.length)];
            activityText.textContent = `${name} from ${location} just created a story`;
        }
    }

    // ============================================
    // A/B TESTING FRAMEWORK
    // ============================================

    /**
     * A/B Testing framework
     * Ready for testing headlines, CTAs, colors, etc.
     */
    window.ABTest = {
        /**
         * Get variant for a test
         * @param {string} testName - Name of the test
         * @param {Array} variants - Array of variant names
         * @returns {string} Selected variant
         */
        getVariant: function(testName, variants) {
            // Check if variant already assigned (persist across page loads)
            const storageKey = `ab_test_${testName}`;
            let variant = localStorage.getItem(storageKey);
            
            if (!variant || !variants.includes(variant)) {
                // Assign random variant
                variant = variants[Math.floor(Math.random() * variants.length)];
                localStorage.setItem(storageKey, variant);
                
                trackEvent('ab_test_assigned', {
                    test_name: testName,
                    variant: variant
                });
            }
            
            return variant;
        },

        /**
         * Apply variant to element
         * @param {string} selector - CSS selector
         * @param {Object} variants - Object with variant names as keys and values as content
         */
        applyVariant: function(selector, variants) {
            const element = document.querySelector(selector);
            if (!element) return;

            const variantNames = Object.keys(variants);
            const selectedVariant = this.getVariant(selector, variantNames);
            const variantValue = variants[selectedVariant];

            if (typeof variantValue === 'string') {
                element.textContent = variantValue;
            } else if (typeof variantValue === 'object') {
                Object.assign(element.style, variantValue);
            }
        }
    };

    // Example A/B test setup (commented out - uncomment to use)
    /*
    document.addEventListener('DOMContentLoaded', function() {
        // Test headline variants
        const headlineVariants = {
            'variant_a': 'Magical Bedtime Stories Starring Your Child',
            'variant_b': 'Personalized Adventures That Make Bedtime the Best Time',
            'variant_c': 'Your Child Deserves Stories as Unique as They Are'
        };
        window.ABTest.applyVariant('.hero-headline', headlineVariants);
    });
    */

    // ============================================
    // INITIALIZATION
    // ============================================

    /**
     * Initialize all features when DOM is ready
     */
    function init() {
        // Language switcher (must be first to set up translations)
        initLanguageSwitcher();
        
        // Core tracking
        initScrollDepthTracking();
        initCTATracking();
        initFormAbandonmentTracking();
        
        // Conversion features
        initExitIntentPopup();
        initStickyMobileCTA();
        
        // UX enhancements
        initScrollReveal();
        initSmoothScroll();
        initRealTimeActivity();
        
        // Performance
        initLazyLoading();
        preloadCriticalResources();
        
        // Track page view
        trackEvent('page_view', {
            page: 'landing',
            timestamp: Date.now(),
            referrer: document.referrer || 'direct'
        });
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    // Track time on page before unload
    window.addEventListener('beforeunload', function() {
        const timeOnPage = Math.round((Date.now() - performance.timing.navigationStart) / 1000);
        trackEvent('page_exit', {
            time_on_page: timeOnPage,
            timestamp: Date.now()
        });
    });

})();

