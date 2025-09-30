/* not used - function to redisplay all data on the tour filter */
  $('a#showAll').click(function() {

    $("article").each(function(){
      $(this).show();
    });

    document.getElementById("counter").innerHTML='[% itineraries.size %] tours found' ;
    document.getElementById("showAll").innerHTML='&nbsp;';

    [% FOREACH trip in tripideas -%] 
    document.getElementById("[% trip.url %]").checked = true;
    [% END %]
    
    $(function() { 
      var $slide = $("#price-range").slider({
        range: true,
        values: [ [% min_cost %], [% max_cost %] ],
        min: [% min_cost %],
        max: [% max_cost %]
      });
        $slide.slider("option", "min", [% min_cost %]); // left handle should be at the left end, but it doesn't move
        $slide.slider("value", $slide.slider("value")); //force the view refresh, re-setting the current value
      });

    $(".min-price-label").html( "[% currency %] " + [% min_cost %]);
    $(".max-price-label").html( "[% currency %] " + [% max_cost %]);

    $(function() { 
      var $slide = $("#duration-range").slider({
        range: true,
        min: [% min_duration %],
        max: [% max_duration %],
        values: [ [% min_duration %], [% max_duration %] ],
      });
      $slide.slider("option", "min", [% min_duration %]); 
      $slide.slider("value", $slide.slider("value")); 
    });
    $(".min-duration-label").html( [% min_duration %] + " days" );
    $(".max-duration-label").html( [% max_duration %] + " days" );

