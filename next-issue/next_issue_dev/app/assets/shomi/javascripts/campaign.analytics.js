/**
 * Shomi Campaign Analytics (SCA).
 * Tracks any imcoming campaign GET variables passed in the URL, stores them in a cookie to pass internally
 * and appends the same values to any external link out of Shomi Portal.
 * Author: Jonathan Bouganim <jonathan.bouganim@rci.rogers.com>
 * Version: 1.0 - October 19, 2014
 */
(function( $ ) {

	var campaign_variables = [ 'v1', 'cid', 'chid', 'sid', 'dtid' ];
	var cookie_prefix = "sca_";
	var cookie_length = 1; //in days
	if (!window.console) console = {log: function() {}, warn: function() {}};
	var tracki = 10;
	var campaignCookieVars = null;
	var order_id_query = 'order_id';

	var analyticHelper = {
		isEmpty: function(ob) {
			for(var i in ob){ return false;}
			return true;
		},
		toDebug: function() {
			vars = this.getUrlVars();
			return vars.hasOwnProperty('sca_debug');
		},
		//Check if it's an external link or relative link or hash
		isExternal: function(url) {
			var parser = document.createElement('a');
			parser.href = url;
			// If it's a different host we are external
			return (location.host !== parser.host)
		},
		didPurchase: function(urlVars) {
			return urlVars.hasOwnProperty( order_id_query );
		},

		//Cookie get and set functions
		setCookie: function(cname,cvalue,exdays) {
			var d = new Date();
			d.setTime(d.getTime()+(exdays*24*60*60*1000));
			var expires = "expires="+d.toGMTString();
			var max_age = "max-age="+d.toGMTString();
			var path = "path=/";
			document.cookie = cookie_prefix + cname + "=" + cvalue + "; " + expires  + "; " + path + "; " + max_age;
		},

		getCookie: function(cname) {
			var name = cookie_prefix + cname + "=";
			var ca = document.cookie.split(';');
			for(var i=0; i<ca.length; i++) 
			  {
			  var c = $.trim(ca[i]);
			  if (c.indexOf(name)==0) return c.substring(name.length,c.length);
			  }
			return undefined;
		},
		//help to get GET variables
		getUrlVars: function(uri) {
			var url = typeof uri === "undefined" ? window.location.href : uri;
		    var vars = {};
		    var parts = url.replace(/[?&]+([^=&]+)=([^&]*)/gi, function(m,key,value) {
		        vars[key] = value;
		    });
		    return vars;
		},
		//help to set variables in URL
		appendVars: function(url, vars) {
			var parser = document.createElement('a');
			parser.href = url;
			
			//Get our the GET vars in passed URL
			var url_vars = this.getUrlVars(url);
			//Merging/overwriting our campaign vars into exist url var set
			$.extend( url_vars, vars );

			//Create our new url
			var parsedURL = parser.protocol + "//";
			parsedURL += parser.host;
			parsedURL += parser.pathname;
			parsedURL += "?" + $.param(url_vars);
			parsedURL += parser.hash;

			return parsedURL;
		},

		saveCampaignURLVars: function(urlVars) {
			// Check if they match our criteria of what to watch, if so create cookie with value
	     	for(i=0; i<campaign_variables.length; i++) 
	     	{
	     		if ( typeof urlVars[ campaign_variables[i] ] !== "undefined" ) {
	     			analyticHelper.setCookie( campaign_variables[i], urlVars[ campaign_variables[i] ], this.cookie_length )
	     		}
	     	}
		},

		getCampaignCookieVars: function() {
			var vars = {};
			// Check if we have cookies set for our campaign variables
	     	for(i=0; i<campaign_variables.length; i++) 
	     	{	
	     		if ( typeof analyticHelper.getCookie(campaign_variables[i]) !== "undefined" ) {
	     			vars[campaign_variables[i]] = analyticHelper.getCookie(campaign_variables[i]);
	     		}
	     	}
	     	return vars;
		},

		deleteCookies: function(campaignCookieVars) {
			// Check if they match our criteria of what to watch, if so create cookie with value
	     	for(i=0; i<campaign_variables.length; i++) 
	     	{
	     		if ( typeof campaignCookieVars[ campaign_variables[i] ] !== "undefined" ) {
	     			analyticHelper.setCookie( campaign_variables[i], '', -1 );
	     		}
	     	}
		}

	};

	function appendPageLinks(campaignCookieVars) {
		// Append new parsed variables to any external link
     	$( "a" ).each(function() {
  			var url = $( this ).attr( "href" );

  			//Skip over any links that aren't external
  			if (!analyticHelper.isExternal(url)) return true;
  			var parsedURL = analyticHelper.appendVars( url, campaignCookieVars );
  			$( this ).attr( "href", parsedURL );
  			
  			//Debug any parsed URL's
  			if (analyticHelper.toDebug()) console.log(
  			   "**SCA Original URL: " + url +
  			 "\n******* Parsed URL: " + parsedURL);
		});
	}

	function createDTMLater(campaignCookieVars) {
		if (typeof window.rdm.dtm.defaults === "undefined") {
			console.warn('Cannot find the default rdm data layer options.');
			return false;
		}

		var options = window.rdm.dtm.defaults;

		//Don't bother appending URL's if no campaign variables are found
     	if ( !analyticHelper.isEmpty(campaignCookieVars) ) {
     		var appendedPageURL = analyticHelper.appendVars( window.rdm.dtm.defaults.pageURL, campaignCookieVars );

     		var newOptions = {
				pageURL: appendedPageURL,
				options: { 
					campaign: campaignCookieVars.hasOwnProperty('cid') ? campaignCookieVars.cid : 'undefined',
					channel: campaignCookieVars.hasOwnProperty('chid') ? campaignCookieVars.chid : 'undefined',
					source: campaignCookieVars.hasOwnProperty('sid') ? campaignCookieVars.sid : 'undefined',
					details: campaignCookieVars.hasOwnProperty('dtid') ? campaignCookieVars.dtid : 'undefined'
				}	
			};
			$.extend( options, newOptions );
     	}

		window.rdm.dtm.dl = new RdmDtmDataLayer(options, this);
		window._satellite.pageBottom();
	}

	function trackSignInDTM() {
		$(document).on('click', 'a.signin', function() {
			// Track sign in button for DTM
			fireTrackingPixel('https://4493900.fls.doubleclick.net/activityi;src=4493900;type=invmedia;cat=Kql54GfI');

			// Track sign in button for DSM
			fireTrackingPixel('https://4533302.fls.doubleclick.net/activityi;src=4533302;type=Shomi14;cat=Roger0');
		});
	}

	function fireTrackingPixel(pixelUrl) {
		$('body').prepend('<div id="track'+tracki+'"></div>');
		var trackjs = '';
		var axel = Math.random() + "", a = axel * 10000000000000;
		if (typeof pixelUrl === "undefined")
			return false;
		var url = pixelUrl + ';ord=' + a + '?';
        trackjs += '<iframe src="'+url+'" class="hidden"></iframe>';
        document.getElementById('track'+tracki).innerHTML = trackjs;
        tracki++;
	}

	function setPageLinks() {

		// Track sign in button for DTM
		trackSignInDTM();
     	
     	//Don't bother appending URL's if no campaign variables are found
     	if ( analyticHelper.isEmpty(campaignCookieVars) ) return false;

     	//If we land on confirmation page, delete the campaign set cookies
     	if ( analyticHelper.didPurchase( analyticHelper.getUrlVars()) ) {
     		analyticHelper.deleteCookies(campaignCookieVars);
     		return false;
     	}

     	//Append the campaign cookie vars to all the links on the page
     	appendPageLinks(campaignCookieVars);

     }

    function loadCampaignAnalytics() {
    	// Get all our url vars
     	var urlVars = analyticHelper.getUrlVars();

     	//Save the campaign vars to cookies, saves each campaign var seperately
     	analyticHelper.saveCampaignURLVars( urlVars );

     	//Get any campaign vars saved in cookies
     	campaignCookieVars = analyticHelper.getCampaignCookieVars();

     	//Add the campaign vars to the rdm.dtm.dl pageURL layer options
     	createDTMLater(campaignCookieVars);
    }

    loadCampaignAnalytics();

    //Precaution not to overwrite any existing onload functions
	var oldonload = window.onload;
 	window.onload = (typeof window.onload != "function") ?
       setPageLinks : function() { oldonload(); setPageLinks(); };

} )( jQuery );