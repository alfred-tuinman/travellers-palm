'use strict';

var Odyssey = Odyssey || {};

(function(ns, undefined) {
    
    ns.ItinFilter = function(contentContainer, itinContainer) {
        
        this.contentContainer = contentContainer;
        this.itinContainer = itinContainer;

        this.PriceRange = null;
        this.Duration   = null;
             
        this.PriceRangeDisplay = null;
        this.DurationDisplay   = null;
         
        this.PriceRange = 0;
        this.Duration   = 0;
               
        return this;
    };
    
    ns.ItinFilter.prototype.setPriceRange = function(element, min, max, step) {
        
        this.PriceRange = element;
        var self = this;

        $(element).slider({
            min: min,
            max: max,
            step: step || 1,
            range: 'min',
            slide: function( event, ui ) {
                
                self.setCost(ui.value).filter();
                
            }
        });
        
        this.PriceRangeDisplay = $(element).siblings('input');

        return this;
    };
    
    ns.ItinFilter.prototype.setDuration = function(element, min, max, step) {
        
        this.daysSlider = element;
        var self = this;

        $(element).slider({
            min: min,
            max: max,
            step: step || 1,
            range: 'min',
            slide: function( event, ui ) {
                
                self.setDays(ui.value).filter();
            }
        });
        
        this.daysDisplay = $(element).siblings('input');
        return this;
    };
    
    ns.ItinFilter.prototype.setSliderOption = function(slider, name, value) {
    
        $(slider).slider('option', name, value);    
        return this;
    };
    
    // All setters return this so calls can be chained
    ns.ItinFilter.prototype.setCost = function(cost) {
        
        this.cost = cost;
        $(this.costSlider).slider('value', cost);
        $(this.costDisplay).val(cost);

        return this;        
    };
    
    ns.ItinFilter.prototype.setDuration = function(days) {
        
        this.days = days;
        $(this.daysSlider).slider('value', days);
        $(this.daysDisplay).val(days);
        
        return this;
    };
    
    
    ns.ItinFilter.prototype.getCost = function() {
        
        return this.cost;
        
    };
    
    ns.ItinFilter.prototype.getDuration = function() {
        
        return this.days;
        
    };

    ns.ItinFilter.prototype.filter = function() {
        
        var costMax = this.getCost(),
            daysMax = this.getDuration(),
            var $count=0;
            var $tours=0;
        
        $(this.contentContainer)
            .children(this.itinContainer)
            .each(function(){
            
            var $obj = $(this),
                cost = $obj.attr('price-range'),
                days = $obj.attr('duration');
            
            $tours++;
            if ((cost > costMax) || (days > daysMax)) {
                $obj.hide();
            }
            else {
                $obj.show();
                $count++;
            }
            document.getElementById("counter").innerHTML=$count + ' of ' + $tours + ' tours showing' ; 
            if ($count < $tours) {
                document.getElementById("showAll").innerHTML='Show all';
            }
        }); 
    }
    
    
}(Odyssey))

