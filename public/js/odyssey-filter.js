$(document).ready(function(){
    
    // Create the filter
    var itinFilter = new Odyssey.ItinFilter('#itineraries', '.itin');
    
    // Initialize it. Done.
    itinFilter
        .setCostSlider('#price-range', 200, 1500, 100)
        .setDaysSlider('#day-range', 3, 30)
        .setCost(1500)
        .setDays(30)
   

    $('a#showAll').click(function() {
    var itinFilter = new Odyssey.ItinFilter('#itineraries', '.itin');
    itinFilter
        .setCostSlider('#price-range', 200, 1500, 100)
        .setDaysSlider('#day-range', 3, 30)
        .setCost(1500)
        .setDays(30)

        $(this.contentContainer)
            .children(this.itinContainer)
            .each(function(){
            
            var $obj = $(this);
                $obj.show();
            })

        document.getElementById("counter").innerHTML='All tours showing' ;
        document.getElementById("showAll").innerHTML='';
    });

 })