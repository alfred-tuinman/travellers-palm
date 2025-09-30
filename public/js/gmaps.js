/**
 * @author guru
 * world-map-section 
 */
 
 tjq(document).ready(function() {

	var baseprefix = tjq('body').attr('baseprefix');
	
	var india = new google.maps.LatLng(23.268764, 81.474609);
	var mapOptions = {
		zoom: 5,
		center: india,
		mapTypeControl: false,
		mapTypeId: google.maps.MapTypeId.TERRAIN
	};
	var myMap = new google.maps.Map(document.getElementById("thememap"), mapOptions);

	var myMarkers    = new Array();
	var myListeners  = new Array();
	var currsubtheme = 0;


	tjq("form#subthemelist input").click(function() {

		myMap.panTo(india);
		var subthemeid = tjq(this).attr('value');
		var added;
		
		if (currsubtheme > 0) {
			var arrlen = myMarkers[currsubtheme].length;
			for (var i = 0; i < arrlen; ++i) {

				var lstnr = myListeners[currsubtheme].pop();
				google.maps.event.removeListener(lstnr);
				
				var marker = myMarkers[currsubtheme].pop();
				marker.setMap(null);
			}
			delete myListeners[currsubtheme];
			delete myMarkers[currsubtheme];
		}

		tjq(this).parent('li').append('<span><img src="' + baseprefix + '/images/themes/ajax-loader.gif" width="16" height="16" />Getting the data...</span>');
		added = tjq(this).siblings('span');

		var uri = baseprefix + '/themes/themename/' + subthemeid;
		tjq.getJSON(
			uri,
			function (data) {

				myMarkers[subthemeid]   = new Array();
				myListeners[subthemeid] = new Array();
				
				tjq.each(data.mapcities, function(i, city) {
					var marker = new google.maps.Marker({
						position: new google.maps.LatLng(this.lat, this.lng),
						map: myMap,
						title: this.name,
						cityid: this.id
					});
					myMarkers[subthemeid].push(marker);
					
					var lstnr = google.maps.event.addListener(
						marker, 
						'click', 
						function() {
							tjq.get(
								uri + '/' + this.cityid,
								function(data) {
									tjq('#themecitydesc').html(data);
									tjq('#themedesc').html('');
								}
							);
						}
					);
					myListeners[subthemeid].push(lstnr);
				});
				tjq('#themecitydesc').html('');
				tjq('#themedesc').html('<h1>' + data.subthemename + '</h1><p>' + data.subthemedesc + '</p>');
				added.remove();
			}
		);
		currsubtheme = subthemeid;
	});

});
