(function( window, document ) {

            var player,
            APIModules,
            bcE,
            $videoBox = $('.video-promo'),
            $videoWrap = $('#vid-wrap');

            // Resize HTML player on window resize 
            // http://docs.brightcove.com/en/video-cloud/smart-player-api/samples/responsive-sizing.html
            $(window).resize(debounce(function(){  resizeHTMLPlayer(); },500));
            $(document).ready(function() { bcE = $videoWrap.find('.BrightcoveExperience'); });


            $videoBox.on('playerLoaded', function() {
            	setTimeout(resizeHTMLPlayer,800)
            });

            $videoBox.on('playerClosed', function() {
            	destroyHTMLPlayer();
            });

            var resizeHTMLPlayer = function() {
            	if (typeof window.shomiExperienceModule === "undefined")
              		return false; 

              	if (!$videoBox.hasClass('video-loaded'))
              		return false;

		      	if (window.shomiExperienceModule.experience.type == "html"){
			      	var resizeWidth = $(".BrightcoveExperience").width(),
			            resizeHeight = $(".BrightcoveExperience").height();
			        window.shomiExperienceModule.setSize(resizeWidth, resizeHeight);
		      	}
            }

            var destroyHTMLPlayer = function() {
            	//Destroy HTML player on close
            	if (typeof window.shomiExperienceModule === "undefined")
              		return false;

     			if (window.shomiExperienceModule.experience.type == "html"){
            		$videoWrap.find('.BrightcoveExperience').remove();
            		$videoWrap.prepend(bcE);
            	}	
            }

            window.onTemplateLoad = function(experienceID){
                rogersAnalyticsBrightcoveLoadHandler(experienceID);
                player = brightcove.api.getExperience(experienceID);
                window.shomiPlayer = player.getModule(brightcove.api.modules.APIModules.VIDEO_PLAYER);
                window.shomiExperienceModule = player.getModule(brightcove.api.modules.APIModules.EXPERIENCE); 
                if ( !$videoBox.hasClass( window.shomiExperienceModule.experience.type ) )
                	$videoBox.addClass( window.shomiExperienceModule.experience.type );
            }

            window.onTemplateReady = function(evt){
            }

})(this, this.document);
