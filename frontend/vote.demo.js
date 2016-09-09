var token;
var hashid;
var socialid;
var mHeight;
var mWidth;

var checkin_x = [];
var checkin_y = [];
var checkins = [];
var fristRun = 1;
var mylocation = null;
var sharerLocation;
var sharer;
var map;
var viewCenter;
var polyline;
var multiPolyline;
var markers;
var stop_maker;
var start_maker;
var num_of_checkin = -1;
var num_of_point = 0;
var segment_num = 0;
var prevRange =1;
var currentRange =0;
var routePolyline
var firstLine =1;
var first_time=0;
var timer;
var color_b =['#FF0088','#FF88C2','#33CCFF','#33FFFF','#00AA55','#00DD00','#FFFF00','#FFBB00','#EE7700','#FF0000'];
var color_a =['#227700','#55AA00','#66DD00','#77FF00','#BBFF00','#FFFF00','#FFBB00','#FF8800','#FF5511','#FF0000'];
var traj =[14,15,26,34,48,69,77,93,95,111,113,123,124,135,140,148,150,160,171,197];

function locate() {
	map.panTo(sharerLocation);
}
$.uniqID = function (separator) {
    var delim = separator || "-";
    function S4() {
        return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    }
    return (S4() + S4()  );
}
function clearMap() {
	map.removeLayer(stop_maker);
	map.removeLayer(start_maker);
    for(i in map._layers) {
        if(map._layers[i]._path != undefined) {
            try {
                map.removeLayer(map._layers[i]);
            }
            catch(e) {
                console.log("problem with " + e + map._layers[i]);
            }
        }
    }
}

function putSpeed(range, latlon,speed,id,time) { 
						var myIcon =L.divIcon({className: 'my-div-icon'})
                        var shareIcon = L.icon({
                        iconUrl: 'images/speed_new_bar/speed_'+range+'0.png',
						iconSize: [20, 20],
                        });
						//var speedMarker = L.marker(latlon).addTo(map).bindPopup("speed: "+speed+"<br/>time: "+time);
				        var speedMarker = L.marker(latlon,{icon:myIcon,title:"id: "+id+"speed: "+speed+"\ntime :"+time}).addTo(map).bindPopup("id: "+id+"<br/>speed: "+speed+"<br/>time :"+time);
	} 
function makeRoute(a,range) { 
	routePolyline = new L.Polyline(a, { color: get_my_color(range), opacity: 100 });
	routePolyline.addTo(map); 
	} 
function animation(currentRange,prevRange,curLatLng,prevLatLng){
	var full =[];
	if (currentRange == prevRange){
						    routePolyline.addLatLng(curLatLng);
							
						
						}else{
						
						full =[];
						full.push(prevLatLng);
						full.push(curLatLng);
						makeRoute(full,currentRange);
						
						}
	clearInterval(timer);
	}
function get_my_color(range) { 
	/*var letters = '0123456789ABCDEF'.split(''); 
	var color = '#'; 
	for (var i = 0; i < 6; i++) 
	{ color += letters[Math.round(Math.random() * 15)];
	}
    return color; 	*/
	return color_a[10-range];
	}

$.drawTrip = function(token){
	var trip =[];
	var full =[];
	var stime;
	var etime;
	var eta;
	var distance;
	var speed;
	//console.log(token);
   
	var url = "http://www.plash.tw/~mikelin/tp_get.php";
	var obj;
	
   $.post(url, { 'token' : token }, function(data){
    $('#loadingbox').overlay().close();
	//alert(JSON.data));
       obj = JSON.parse(data);
	   //alert(obj.length);
	   //obj.length)
			var curLatLng,prevLatLng,rawLatLng,rawprevLatLng,first_ptr, currLatLng, prevVelocity, prevDistance, totalDistance, avgVelocity, points;
			var contents="";
			var first =true;
			for (var i=0; i< obj[0].length; i++){
			 console.log(obj[0][i]);
			 
			
        	
				contents = contents+obj[0][i].lat+","+obj[0][i].lng+","+obj[0][i].speed+","+obj[0][i].time_in_timestamp+"\r\n";
				var lat = obj[0][i].lat;
                var lng = obj[0][i].lng;
				
                curLatLng = L.latLng(lat, lng);
				if (i==0){
				  var myIcon =L.icon({
					iconUrl: 'icons/Sonic.png',
					iconSize:     [40, 55],
					iconAnchor:   [5, 50]
					});
				  start_marker = L.marker(curLatLng,{icon:myIcon}).addTo(map);
                  map.panTo(curLatLng);
				}
				if (i==(obj[0].length-1)){
				var stopIcon =L.icon({
				iconUrl: 'icons/destination.png',
				iconSize:     [100, 141],
	            iconAnchor:   [50, 120]
				});
				// var myIcon =L.divIcon({className: 'my-div-icon'});
				 stop_maker = L.marker(curLatLng,{icon:stopIcon}).addTo(map);
                // marker.valueOf()._icon.style.backgroundColor = 'red';
				}
				
				switch(Math.ceil(obj[0][i].speed/10)) {
						case 0: // Integer is between 1-10
							currentRange =1 ;
							break;
						case 1: // Integer is between 1-10
							currentRange =1 ;
							break;
						case 2: // Integer is between 11-20
							currentRange =2 ;
							break;
						case 3: // Integer is between 21-30
							currentRange =3 ;
							break;
						case 4: // Integer is between 31-40
							currentRange =4 ;
							break;
						case 5: // Integer is between 41-50
							currentRange =5 ;
							break;
						case 6: // Integer is between 51-60
							currentRange =6 ;
							break;
						case 7: // Integer is between 61-70
							currentRange =7 ;
							break;
						case 8: // Integer is between 71-80
							currentRange =8 ;
							break;
						case 9: // Integer is between 81-90
							currentRange =9 ;
							break;
						default:
							currentRange =10 ;
							break;
						}
				//alert("range:"currentRange);
				//alert("speed:"obj[0][i].speed);
				if (obj[0][i].speed == 0){
				putSpeed(0,curLatLng,0,obj[0][i].id,obj[0][i].time_in_timestamp);
				}else{
				putSpeed(currentRange,curLatLng,obj[0][i].speed,obj[0][i].id,obj[0][i].time_in_timestamp );
				}
				full.push(curLatLng);
				//alert("range:"+currentRange);
				//setTimeout(function(){
				if (first_time == 0){			
				first_time =1;
				}else{
					
					if (firstLine == 1 ){
					firstLine = 0;
					makeRoute(full,currentRange);
					}else{
						//timer=setInterval(animation(currentRange,prevRange,currLatLng,prevLatLng),500);;
						
						if (currentRange == prevRange){
						    routePolyline.addLatLng(curLatLng);
							
						
						}else{
						
						full =[];
						full.push(prevLatLng);
						full.push(curLatLng);
						makeRoute(full,currentRange);
						
						}
					}
					
						
				}
					
				
				
				
						prevLatLng= curLatLng;
						prevRange = currentRange;
				
				
			    //console.log(obj[1][i]);
		if (i< obj[1].length){
			    var lat = obj[1][i].lat;
                var lng = obj[1][i].lng;
				var pre_time = obj[1][i].time;
                rawLatLng = L.latLng(lat, lng);
				
				
				trip.push(rawLatLng);
				
				
				if (first){
					rawprevLatLng =rawLatLng; 
					stime=obj[1][i].epoch_time;
					first=false;
					putSpeed(0,rawLatLng,0,obj[1][i].id,obj[1][i].time );
				
				}else{
					etime=obj[1][i].epoch_time;
					full.push(rawprevLatLng);
					full.push(rawLatLng);
					Distance=rawprevLatLng.distanceTo(rawLatLng);
					//console.log(Distance*3.6/(etime-stime));
					velocity=Distance*3.6/(etime-stime);
					switch(Math.ceil(velocity/10)) {
						case 0: // Integer is between 1-10
							currentRange =1 ;
							break;
						case 1: // Integer is between 1-10
							currentRange =1 ;
							break;
						case 2: // Integer is between 11-20
							currentRange =2 ;
							break;
						case 3: // Integer is between 21-30
							currentRange =3 ;
							break;
						case 4: // Integer is between 31-40
							currentRange =4 ;
							break;
						case 5: // Integer is between 41-50
							currentRange =5 ;
							break;
						case 6: // Integer is between 51-60
							currentRange =6 ;
							break;
						case 7: // Integer is between 61-70
							currentRange =7 ;
							break;
						case 8: // Integer is between 71-80
							currentRange =8 ;
							break;
						case 9: // Integer is between 81-90
							currentRange =9 ;
							break;
						default:
							currentRange =10 ;
							break;
						}
						putSpeed(0,rawLatLng,velocity,obj[1][i].id,obj[1][i].time );
				
				
					
					
					rawprevLatLng =rawLatLng;
					stime=etime;
					//full=[];
				}
			
				}
			
		
			}
			
			//polyline = L.polyline(trip, {color: '#000000',weight:3}).addTo(map);
			polyline = L.polyline(trip, {color: '#0000FF',weight:3}).addTo(map);
		    //map.fitBounds(polyline.getBounds());
			
	
           
			
		
		
   })
	
	
	}
$.vote = function(token){
	token++;
	$.cookie('demo' , token);
	window.location.href = 'vote_demo.html';
	/*
	var acc =$.cookie("acc" );
	var bac =$.cookie("bac" );
	 var id = $.cookie("id" );
	
	var url = "http://www.plash.tw/~mikelin/vote.php";
	
	//console.log(token+acc);
	$.post(url, { "traj_id": traj[token], "basic": bac, "adept": 3, "accuracy": acc, "id": id}, function(data){
      obj = JSON.parse(data);
	  console.log(obj.status_code);
	  if(obj.status_code ==200){
		token++;
		$.cookie('demo' , token );
		window.location.href = 'vote_demo.html';
	  }
	   
   })*/
}
$.start = function(token){
	var acc =$.cookie("acc" );
	var bac =$.cookie("bac" );
	 var id = $.cookie("id" );
	
	var url = "http://www.plash.tw/~mikelin/vote.php";
	
	//console.log(token+acc);
	$.post(url, { "traj_id": traj[token], "basic": bac, "adept": 0, "accuracy": -1, "id": id}, function(data){
      obj = JSON.parse(data);
	  //console.log(obj.status_code);

	  })
	   
}

var currentValue = 0;
    function handleClick(myRadio) {
	$.cookie('bac', myRadio.value );
	$.cookie('radio', myRadio.id );
	$("#myForm").remove();
	$('#map_canvas').height($(window).height() - $('#header').height() - $('#panel').height()-$('#myForm').height()-$('#accuracy').height()- 2);

	//alert($.cookie("radio" ));
    //currentValue = myRadio.value;
   }
 
var currentValue = 0;
   function accClick(myRadio) {
	$.cookie('acc', myRadio.value );
	//alert($.cookie("acc" ));
	if(token != null){
		$.vote(token);
	}else{
		window.location.href = 'vote_demo.html';
	}
	
   }

$(document).bind("mobileinit", function () {
    $.mobile.pushStateEnabled = true;
	$('#menu').hide();	
});
 
$(document).ready(function () {
    var menuStatus;
	mHeight = Math.round($(window).height()*0.8); 
	mWidth = Math.round($(window).width()*0.8);
	$('#loadingbox').overlay({
		top: Math.round($(window).height()*0.7),
        mask: {
            color: '#fff',
            loadSpeed: 200,
            opacity: 0.3
        },
        closeOnClick: true,
        load: false 
    });
    $('#loadingbox').overlay().load();
   $('#closebox').overlay({
		top: Math.round($(window).height()*0.4),
    	mask: {
        	color: '#FFFFFF',
            loadSpeed: 1000,
            opacity: 1
        }, 
		closeOnClick: false,
		load: false
	});
	$('label[for=acc1]').html("strongly disagree");
	$('label[for=acc2]').html("disagree");
	$('label[for=acc3]').html("neutral");
	$('label[for=acc4]').html("agree");
	$('label[for=acc5]').html("strongly agree");
	var tmp = $.cookie('demo');
	//console.log(tmp);
	if (tmp != null){
		token = $.cookie('demo');
		var message = "The predicted path is more accurate than the GPS trajectory, when comparing it to the actual path.("+ (parseInt(token)+1) +"/20)";
        $('#question').html(message);
	}else{
		token = 0;
		var message = "The predicted path is more accurate than the GPS trajectory, when comparing it to the actual path. ("+ (parseInt(token)+1) +"/20)";
        $('#question').html(message);
	}
	if(tmp == 20){
		var message = "Click any to proceed!";
        $('#question').html(message);
		$('label[for=acc1]').html(message);
		$('label[for=acc2]').html(message);
		$('label[for=acc3]').html(message);
		$('label[for=acc4]').html(message);
		$('label[for=acc5]').html(message);
		token = null;
		$.cookie('demo' ,null );
		$.cookie("radio",null );
		$.cookie("bac",null );
		$.cookie("id",null );
		$("#myForm").remove();
		$('#closebox').overlay().load();
		map.removeControl(legend);
		
	}
    //$.start(token);
   	hashid = $.cookie("id" );
    if(hashid==null) {
		hashid = $.uniqID(1);
        $.cookie("id", hashid );
    }
	
	
	var myRadio = $.cookie("radio" );
	if(myRadio != ""){
		
		//console.log($('#'+myRadio ).val());
		
		$('#'+myRadio).attr('checked', true).trigger('click');
		
	}
	

	$('#map_canvas').height($(window).height() - $('#header').height() - $('#panel').height()-$('#myForm').height()-$('#accuracy').height()- 2);
	map = L.map('map_canvas').setView([25.04,121.61],16);
	L.tileLayer(
		//'http://map.plash.tw/osm_tiles/{z}/{x}/{y}.png', {
		//'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
		'https://{s}.tiles.mapbox.com/v3/{id}/{z}/{x}/{y}.png', {
		id: 'yuhsiang.jj9a0gd4',
		maxZoom: 24,
		attribution: '<a href="http://openstreetmap.org">OpenStreetMap</a>, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>'
	}).addTo(map);
	//var googleLayer = new L.Google('ROADMAP');
	//map.addLayer(googleLayer);
	markers = L.markerClusterGroup({spiderfyDistanceMultiplier:3,maxClusterRadius:120});
	//viewCenter = new L.Control.ViewCenter();
	//map.addControl({token++;window.location.href = 'traj_match.html?traj_id='+token; });
	/*map.on("locationfound", function(location) {
    	if (!mylocation)
        	//mylocation = L.userMarker(location.latlng,{pulsing:true}).addTo(map);

    	mylocation.setLatLng(location.latlng);
    	mylocation.setAccuracy(location.accuracy);
	});
	map.locate({
    	watch: true,
    	locate: true,
    	setView: false,
    	enableHighAccuracy: true
	});	*/	
	//setTimeout($.drawTrip(token), 1000);
	
	var legend = L.control({position: 'bottomright'});

	legend.onAdd = function (map) {

    var div = L.DomUtil.create('div', 'info legend'),
        grades = [0,1, 2, 3, 4, 5, 6, 7, 8,9],
        labels = [];
		div.innerHTML +=
            '<i style="background: #FF0000 "></i> '+'predicted path<br>';

		
	div.innerHTML +=
            '<i style="background: #FFFFFF , opacity:0.8 "></i> '+'<br>';
 div.innerHTML +=
            '<i style="background: #0000FF  "></i> '+'GPS trajectory<br>';
	
	
			
	
            
    return div;
	};

	legend.addTo(map);
	
	//gettrip = setInterval(function(){$.drawTrip(token)},100);
	$.drawTrip(traj[token]);
    
	
	$(window).unload(function(){
        //alert("close page");
        var url = "http://www.plash.tw/api/antrack/stopwatch.php";
                $.post(url, { 'demo' : token, "hashid": hashid }, function(data){
                        if (data.status_code != "200") {
                        }
                });
    });
/*
    $(window).bind('beforeunload', function() {
        alert("close page 1");
        var url = "http://www.plash.tw/api/antrack/stopwatch.php";
                $.post(url, { 'demo' : token, "hashid": hashid }, function(data){
                        if (data.status_code != "200") {
                        }
                });
    });
*/
});

