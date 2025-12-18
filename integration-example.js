/**
 * INTEGRATION EXAMPLE
 * 
 * This file shows how to integrate the landing page with your backend API.
 * Copy the relevant functions to script.js and update with your API endpoints.
 */

// ============================================
// EXAMPLE: Form Submission to Backend
// ============================================

/**
 * Example: Submit signup form to your FastAPI backend
 */
async function submitSignupForm(email) {
    try {
        const response = await fetch('https://your-api-domain.com/api/auth/signup', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                email: email,
                source: 'landing_page',
                timestamp: new Date().toISOString()
            })
        });

        if (!response.ok) {
            throw new Error('Signup failed');
        }

        const data = await response.json();
        
        // Track successful signup
        trackEvent('signup_success', {
            email: email, // Hash in production
            user_id: data.user_id
        });

        // Redirect to onboarding or dashboard
        if (data.redirect_url) {
            window.location.href = data.redirect_url;
        } else {
            window.location.href = '/signup?email=' + encodeURIComponent(email);
        }

        return data;
    } catch (error) {
        console.error('Signup error:', error);
        
        // Track error
        trackEvent('signup_error', {
            error: error.message,
            email: email
        });

        // Show error message to user
        showErrorMessage('Something went wrong. Please try again.');
        throw error;
    }
}

// ============================================
// EXAMPLE: Google Analytics 4 Integration
// ============================================

/**
 * Add this to your HTML head section:
 * 
 * <!-- Google tag (gtag.js) -->
 * <script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
 * <script>
 *   window.dataLayer = window.dataLayer || [];
 *   function gtag(){dataLayer.push(arguments);}
 *   gtag('js', new Date());
 *   gtag('config', 'G-XXXXXXXXXX');
 * </script>
 */

function trackEventGA4(eventName, eventData = {}) {
    if (typeof gtag !== 'undefined') {
        gtag('event', eventName, eventData);
    }
}

// ============================================
// EXAMPLE: Mixpanel Integration
// ============================================

/**
 * Add this to your HTML head section:
 * 
 * <!-- Mixpanel -->
 * <script type="text/javascript">
 *   (function(c,a){if(!a.__SV){var b=window;try{var d,m,j,k=b.location,f=k.hash;d=function(a,b){return(m=a.match(RegExp(b+"=([^&]*)")))?m[1]:null};if(f&&d(f,"state")){j=JSON.parse(decodeURIComponent(d(f,"state")));"mpeditor"===j.action&&(b.sessionStorage.setItem("_mpcehash",f),history.replaceState(j.desiredHash||"",c.title,k.pathname+k.search))}}catch(n){}var l,h;window.mixpanel=a;a._i=[];a.init=function(b,d,g){function c(b,i){var a=i.split(".");2==a.length&&(b=b[a[0]],i=a[1]);b[i]=function(){b.push([i].concat(Array.prototype.slice.call(arguments,0)))}}var e=a;"undefined"!==typeof g?e=a[g]=[]:g="mixpanel";e.people=e.people||[];e.toString=function(b){var a="mixpanel";"mixpanel"!==g&&(a+="."+g);b||(a+=" (stub)");return a};var f="init identify track track_pageview track_links track_forms register register_once alias unregister opt_out_tracking opt_in_tracking opt_out_tracking_by_cookie opt_in_tracking_by_cookie has_opted_out_tracking has_opted_in_tracking clear_opt_out_tracking people.set people.set_once people.unset people.increment people.append people.union people.track_charge people.clear_charges people.delete_user".split(" "),i;for(i=0;i<f.length;i++)c(e,f[i]);var j="set set_once unset increment append union track_charge clear_charges delete_user".split(" "),k="set set_once".split(" "),m;e.get_distinct_id=function(){var a=c.getItem("mp_distinct_id");if(a)return a;a=function(){var b=new Date,c=Math.random().toString(36).substring(2,15)+Math.random().toString(36).substring(2,15);return"mp_"+b.getTime()+"_"+c}();c.setItem("mp_distinct_id",a);return a};for(m=0;m<j.length;m++)c(e.people,j[m]);e._i.push([b,d,g])};a.__SV=1.2;b=c.createElement("script");b.type="text/javascript";b.async=!0;b.src="undefined"!==typeof MIXPANEL_CUSTOM_LIB_URL?MIXPANEL_CUSTOM_LIB_URL:"file://"===c.location.protocol&&"//cdn.mixpanel.com".match(/^\/\//)?"https://cdn.mixpanel.com":c.location.protocol+"//cdn.mixpanel.com";b.onload=function(){if("undefined"!==typeof a){l=a.init("YOUR_MIXPANEL_TOKEN");h=a}};d=c.getElementsByTagName("script")[0];d.parentNode.insertBefore(b,d)}})(document,window.mixpanel||[]);
 * </script>
 */

function trackEventMixpanel(eventName, eventData = {}) {
    if (typeof mixpanel !== 'undefined') {
        mixpanel.track(eventName, eventData);
    }
}

// ============================================
// EXAMPLE: Supabase Integration
// ============================================

/**
 * If using Supabase for authentication:
 * 
 * <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
 */

async function signupWithSupabase(email) {
    // Initialize Supabase client
    const { createClient } = supabase;
    const supabaseUrl = 'YOUR_SUPABASE_URL';
    const supabaseKey = 'YOUR_SUPABASE_ANON_KEY';
    const supabaseClient = createClient(supabaseUrl, supabaseKey);

    try {
        // Send magic link or create user
        const { data, error } = await supabaseClient.auth.signInWithOtp({
            email: email,
            options: {
                emailRedirectTo: 'https://yourdomain.com/dashboard'
            }
        });

        if (error) throw error;

        trackEvent('supabase_signup_initiated', {
            email: email
        });

        return data;
    } catch (error) {
        console.error('Supabase signup error:', error);
        trackEvent('supabase_signup_error', {
            error: error.message
        });
        throw error;
    }
}

// ============================================
// EXAMPLE: Error Handling UI
// ============================================

function showErrorMessage(message) {
    const form = document.getElementById('signupForm');
    if (!form) return;

    // Remove existing error messages
    const existingError = form.querySelector('.form-error');
    if (existingError) {
        existingError.remove();
    }

    // Create error message
    const errorDiv = document.createElement('div');
    errorDiv.className = 'form-error';
    errorDiv.style.cssText = `
        background: #FF6B6B;
        color: white;
        padding: 1rem;
        border-radius: 8px;
        margin-bottom: 1rem;
        text-align: center;
        animation: fadeIn 0.3s ease;
    `;
    errorDiv.textContent = message;

    form.insertBefore(errorDiv, form.firstChild);

    // Auto-remove after 5 seconds
    setTimeout(() => {
        errorDiv.remove();
    }, 5000);
}

// ============================================
// EXAMPLE: Update script.js form handler
// ============================================

/**
 * Replace the form submission handler in script.js with:
 * 
 * form.addEventListener('submit', async function(e) {
 *     e.preventDefault();
 *     
 *     const email = emailInput.value.trim();
 *     
 *     if (!email || !isValidEmail(email)) {
 *         showErrorMessage('Please enter a valid email address');
 *         return;
 *     }
 *     
 *     // Disable form during submission
 *     submitButton.disabled = true;
 *     submitButton.textContent = 'Creating...';
 *     
 *     try {
 *         await submitSignupForm(email);
 *         // Success handled in submitSignupForm
 *     } catch (error) {
 *         // Error handled in submitSignupForm
 *         submitButton.disabled = false;
 *         submitButton.textContent = 'Create My Child\'s First Story Free';
 *     }
 * });
 * 
 * function isValidEmail(email) {
 *     return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
 * }
 */

