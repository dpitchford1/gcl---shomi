FSR.surveydefs = [{
    name: 'mobile_web',
    pin: 1,
    invite: {
        when: 'onentry',
        dialogs: [[{
            reverseButtons: false,
            headline: "Vos commentaires sont les bienvenus!",
            blurb: "Pouvons-nous vous envoyer par courriel ou message texte un sondage sur la satisfaction de la clientèle pour améliorer votre expérience sans-fil?",
            attribution: "Mené par ForeSee.",
            declineButton: "Non merci",
            acceptButton: "Oui"
        
        }], [{
            reverseButtons: false,
            headline: "Merci de nous aider!",
            blurb: "Veuillez entrer votre adresse de courriel ou votre numéro de sans-fil (É.-U. et Canada). Après avoir quitté le site, nous vous enverrons un lien vers le sondage. Les tarifs de messagerie texte s’appliquent.",
            attribution: "ForeSee <a class='fsrPrivacy' href='//www.foresee.com/privacy-policy.shtml' target='_blank'>Politique de confidentialité</a>",
            declineButton: "Annuler",
            acceptButton: "Courriel/Message texte",
            mobileExitDialog: {
                support: "b", //e for email only, s for sms only, b for both
                inputMessage: "Adresse de courriel ou numéro de sans-fil",
                emailMeButtonText: "Courriel",
                textMeButtonText: "Message texte",
                fieldRequiredErrorText: "Entrez un numéro de sans-fil ou une adresse de courriel",
                invalidFormatErrorText: "Modèles à suivre : nom@domaine.com ou 123-456-7890"            
            }
        }]]
    },
    pop: {
        when: 'later'
    },
    criteria: {
        sp: 20,
        lf: 2
    },
    platform: 'mobile',
    include: {
        cookies: [{
            name: 'language',
            value: 'fr'
        }]
    }
}, {
    name: 'mobile_web',
    pin: 1,
    invite: {
        when: 'onentry',
        dialogs: [[{
            reverseButtons: false,
            headline: "We'd welcome your feedback!",
            blurb: "Can we email or text you later a brief customer satisfaction survey so we can improve your mobile experience?",
            attribution: "Conducted by ForeSee.",
            declineButton: "No, thanks",
            acceptButton: "Yes, I'll help"
        }], [{
            reverseButtons: false,
            headline: "Thank you for helping!",
            blurb: "Please provide your email address or mobile number (US and CA only). After your visit we'll send you a link to the survey. Text Messaging rates apply.",
            attribution: "ForeSee's <a class='fsrPrivacy' href='//www.foresee.com/privacy-policy.shtml' target='_blank'>Privacy Policy</a>",
            declineButton: "Cancel",
            acceptButton: "email/text me",
            mobileExitDialog: {
                support: "b", //e for email only, s for sms only, b for both
                inputMessage: "email or mobile number",
                emailMeButtonText: "email me",
                textMeButtonText: "text me",
                fieldRequiredErrorText: "Enter a mobile number or email address",
                invalidFormatErrorText: "Format should be: name@domain.com or 123-456-7890"
            }
        }]]
    },
    pop: {
        when: 'later'
    },
    criteria: {
        sp: 20,
        lf: 2
    },
    platform: 'mobile',
    include: {
        urls: ['.']
    }
}, {
    name: 'browse',
	platform: 'desktop',
    section: 'support',
    pin: 1,
    invite: {
        when: 'onentry'
    },
    pop: {
        when: 'later'
    },
    criteria: {
        sp: 10,
        lf: 3
    },
    include: {
        urls: ['/support/', 'support_landing', 'support_wireless', 'support_homephone', 'support_internetServices', 'support_results', 'support_billingPayment', '/moving-your-service', '/new-moves-customers', '/support-moving', '/contactus']
    }
}, {
    name: 'browse',
    section: 'selfserve',
    pin: 1,
    invite: {
        when: 'onentry'
    },
    pop: {
        when: 'later'
    },
    criteria: {
        sp: 10,
        lf: 3
    },
    include: {
        urls: ['/signin', '/registration', '/eBillSignInFlow', '/RogersServices.portal', '/myrogers']
    }
}, {
    name: 'browse',
    invite: {
        when: 'onentry'
    },
    pop: {
        when: 'later'
    },
    criteria: {
        sp: 10,
        lf: 3
    },
    include: {
        urls: ['.']
    }
}];
FSR.properties = {
    repeatdays: 90,
    
    repeatoverride: false,
    
    altcookie: {},
    
    language: {
        locale: 'en',
        src: 'cookie',
        type: 'client',
        name: 'language',
        locales: [{
            match: 'fr',
            locale: 'fr'
        }]
    },
    
    exclude: {},
    
    zIndexPopup: 10000,
    
    ignoreWindowTopCheck: false,
    
    ipexclude: 'fsr$ip',
    
    mobileHeartbeat: {
        delay: 60, /*mobile on exit heartbeat delay seconds*/
        max: 3600 /*mobile on exit heartbeat max run time seconds*/
    },
    
    invite: {
    
        // For no site logo, comment this line:
        siteLogo: "sitelogo.gif",
        
        /* Desktop */
        dialogs: [[{
            reverseButtons: false,
            headline: "We'd welcome your feedback!",
            blurb: "Thank you for visiting our website. You have been selected to participate in a brief customer satisfaction survey to let us know how we can improve your experience.",
            noticeAboutSurvey: "The survey is designed to measure your entire experience, please look for it at the <u>conclusion</u> of your visit.",
            attribution: "This survey is conducted by an independent company ForeSee, on behalf of the site you are visiting.",
            closeInviteButtonText: "Click to close.",
            declineButton: "No, thanks",
            acceptButton: "Yes, I'll give feedback",
            locales: {
                "fr": {
                    reverseButtons: false,
                    headline: "Vos commentaires sont les bienvenus!",
                    blurb: "MNous vous remercions d’avoir consulté notre site web. Vous avez été sélectionné pour répondre à un court sondage sur la satisfaction de la clientèle afin de nous aider à améliorer votre expérience.",
                    noticeAboutSurvey: "Ce sondage a été conçu pour évaluer l'ensemble de votre expérience, veuillez donc le remplir à la fin de votre visite.",
                    attribution: "Ce sondage est mené par l'entreprise indépendante ForeSee au nom du site que vous consultez.",
                    closeInviteButtonText: "Cliquez pour fermer.",
                    declineButton: "Non merci",
                    acceptButton: "Oui"
                }
            }
        }]],
        
        /* Mobile On Exit
         dialogs : [
         [ {
         reverseButtons: false,
         headline: "We'd welcome your feedback!",
         blurb: "Can we email or text you later a brief customer satisfaction survey so we can improve your mobile experience?",
         attribution: "Conducted by ForeSee.",
         declineButton: "No, thanks",
         acceptButton: "Yes, I'll help"
         } ],
         [ {
         reverseButtons: false,
         headline: "Thank you for helping!",
         blurb: "Please provide your email address or mobile number (US and CA only). After your visit we'll send you a link to the survey. Text Messaging rates apply.",
         attribution: "ForeSee's <a class='fsrPrivacy' href='//www.foresee.com/privacy-policy.shtml' target='_blank'>Privacy Policy</a>",
         declineButton: "Cancel",
         acceptButton: "email/text me",
         mobileExitDialog: {
         support:"b", //e for email only, s for sms only, b for both
         inputMessage:"email or mobile number",
         emailMeButtonText:"email me",
         textMeButtonText:"text me",
         fieldRequiredErrorText:"Enter a mobile number or email address",
         invalidFormatErrorText:"Format should be: name@domain.com or 123-456-7890"
         }
         } ] ],
         */
        exclude: {
            local: ['/business/on/en/'],
            referrer: []
        },
        include: {
            local: ['.']
        },
        
        delay: 0,
        timeout: 0,
        
        hideOnClick: false,
        
        hideCloseButton: false,
        
        css: 'foresee-dhtml.css',
        
        hide: [],
        
        hideFlash: false,
        
        type: 'dhtml',
        /* desktop */
        // url: 'invite.html'
        /* mobile */
        url: 'invite-mobile.html',
        back: 'url'
    
        //SurveyMutex: 'SurveyMutex'
    },
    
    tracker: {
        width: '690',
        height: '415',
        timeout: 3,
        adjust: true,
        alert: {
            enabled: true,
            message: 'The survey is now available.'
        },
        url: 'tracker.html',
        locales: [{
            locale: 'fr',
            url: 'tracker_fr.html'
        }]
    },
    
    survey: {
        width: 690,
        height: 600
    },
    
    qualifier: {
        footer: '<div div id=\"fsrcontainer\"><div style=\"float:left;width:80%;font-size:8pt;text-align:left;line-height:12px;\">This survey is conducted by an independent company ForeSee,<br>on behalf of the site you are visiting.</div><div style=\"float:right;font-size:8pt;\"><a target="_blank" title="Validate TRUSTe privacy certification" href="//privacy-policy.truste.com/click-with-confidence/ctv/en/www.foreseeresults.com/seal_m"><img border=\"0\" src=\"{%baseHref%}truste.png\" alt=\"Validate TRUSTe Privacy Certification\"></a></div></div>',
        width: '690',
        height: '500',
        bgcolor: '#333',
        opacity: 0.7,
        x: 'center',
        y: 'center',
        delay: 0,
        buttons: {
            accept: 'Continue'
        },
        hideOnClick: false,
        css: 'foresee-dhtml.css',
        url: 'qualifying.html'
    },
    
    cancel: {
        url: 'cancel.html',
        width: '690',
        height: '400'
    },
    
    pop: {
        what: 'survey',
        after: 'leaving-site',
        pu: false,
        tracker: true
    },
    
    meta: {
        referrer: true,
        terms: true,
        ref_url: true,
        url: true,
        url_params: false,
        user_agent: false,
        entry: false,
        entry_params: false
    },
    
    events: {
        enabled: true,
        id: true,
        codes: {
            purchase: 800,
            items: 801,
            dollars: 802,
            followup: 803,
            information: 804,
            content: 805
        },
        pd: 7,
        custom: {}
    },
    
    previous: false,
    
    analytics: {
        google_local: false,
        google_remote: false
    },
    
    cpps: {
        support_btn: {
            source: 'static',
            value: 'Y',
            query: '#home.support',
            on: 'click'
        },
        username: {
            source: 'cookie',
            name: 'username'
        },
        TLSessionID: {
            source: 'cookie',
            name: 'TLTSID'
        }
    },
    
    mode: 'first-party'
};
