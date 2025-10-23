package TravellersPalm;

use Cache::Memcached;
use Mojo::Base 'Mojolicious', -signatures;
use Mojo::File 'path';
use Mojo::JSON qw(encode_json);
use Mojo::Log;
use File::Spec;
use POSIX qw(strftime);
use Term::ANSIColor;
use Time::HiRes qw(gettimeofday tv_interval);
use TravellersPalm::Constants qw(:all);
use TravellersPalm::Database::Connector qw(setup);


# ----------------------
# Startup
# ----------------------
sub startup ($self) {

    # ----------------------
    # Config
    # ----------------------
    my $config = $self->plugin('yaml_config' => {
        file      => 'config.yml',
        stash_key => 'conf',
        class     => 'YAML::XS',
    });

    $self->{config} = $config;    
    $self->secrets($config->{secrets});

    #----------------------------------
    # Initialize Log directory and file
    #----------------------------------
    my $log_conf = $self->config->{log};

    # Ensure the directory for the log exists
    my $log_path = path($log_conf->{path});
    $log_path->dirname->make_path;

    # Create Mojo::Log
    $self->log(Mojo::Log->new(
      path  => $log_conf->{path},
      level => $log_conf->{level},
    ));

    # Constants for daily rotation in the before_dispatch hook below
    my $log_file = $log_path;           # full path to current log
    my $log_dir  = $log_path->dirname;  # directory containing the log

    #----------------------------------
    # Initialize Memcached manually
    #----------------------------------
    my $memd_conf = $self->config->{memcached};
    my $memd = Cache::Memcached->new({
        servers => $memd_conf->{servers},
        compress_threshold => 10_000,
    });
    $self->helper(memcache => sub { $memd });

    $self->helper(db_call => sub ($c, $db_func, @args) {
        my $result = eval { $db_func->(@args) };
        if ($@) {
            $c->app->log->error("DB exception: $@");
            return $c->render(status => 500, json => { error => 'Database exception' });
        }

        if ($result->{error}) {
            $c->app->log->error("DB error: $result->{error}");
            return $c->render(status => 500, json => { error => 'Database error' });
        }

        return $result;
        }
    );


    # Initialize the connector once
    TravellersPalm::Database::Connector->setup($self);
    
    # ----------------------------
    # --- COLORED LOG FORMATTER ---
    # ----------------------------
    $self->log->format(sub {
        my ($time, $level, @lines) = @_;

        # Pick a color depending on the level
        my %colors = (
            debug => 'cyan',
            info  => 'green',
            warn  => 'yellow',
            error => 'red',
            fatal => 'bright_red on_black',
        );

        my $color = $colors{$level} // 'white';

        # Clean up and concatenate lines
        my $msg = join('', @lines);

        # Trim whitespace and newlines
        $msg =~ s/\s+$//;
        $msg =~ s/^\s+//;

        # Truncate very long messages (like large SQL or Dumper output)
        my $max_len = 200;
        if (length($msg) > $max_len) {
            my $omitted = length($msg) - $max_len;
            $msg = substr($msg, 0, $max_len) . " ... ($omitted more chars)";
        }

        # Format timestamp and process info
        my $header = sprintf("[%s] [pid:%d]", $time, $$);

        # Colorize the level and the message
        my $level_str = color($color) . uc($level) . color('reset');
           $msg       = join('', @lines);

        return sprintf("%s %s %s\n", $header, $level_str, $msg);
    });

     
    # ----------------------
    # TT Renderer
    # ----------------------
    $self->plugin('TtRenderer' => {
        template           => { INTERPOLATE => 1 },
        template_extension => '.tt',
        template_options   => {
            ENCODING     => 'utf8',
            INCLUDE_PATH => File::Spec->catdir($self->home, 'templates'),
        },
    });
    $self->renderer->default_handler('tt');

    # ----------------------
    # Hooks
    # ----------------------
    $self->hook(before => sub ($c) {
        # --- Default session values ---
        $c->session(currency => $c->session('currency') // 'EUR');
        $c->session(country  => $c->session('country')  // 'IN');
        $c->stash(session_currency => $c->session_currency);
    });

    $self->hook(before_dispatch => sub ($c) {
        # --- daily rotation ---
        my $date = strftime('%Y-%m-%d', localtime);
        my $current_log = $log_dir->child("travellers_palm.log.$date");

        unless (-f $current_log) {
            if (-f $log_file) {
                rename $log_file, $current_log;
            }
        }
    });


    $self->hook(after_dispatch => sub ($c) {
        my $route = $c->match->endpoint;

        # Only log if we have a route and it's not the catch-all
        if ($route && $route->can('pattern')) {
            my $pattern = $route->pattern->can('regex') ? $route->pattern->regex : "$route";
            
            # Skip the generic catch-all pattern
            return if $pattern eq '(?^ups:^/(.+))';

            $c->app->log->debug("Matched route: $pattern");
        }
    });


    $self->hook(before_render => sub ($c, $args) {
        my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
        $year += 1900;

        # Get template tokens from config
        my $tokens = $c->app->config->{template_tokens} // {};

        # Convert all keys to uppercase for the stash
        my %stash_tokens = map { uc($_) => $tokens->{$_} } keys %$tokens;

        # Add dynamic values
        $stash_tokens{COUNTRY}  = $c->session('country');
        $stash_tokens{CURRENCY} = $c->session('currency');
        $stash_tokens{YEAR}     = $year;

        # Inject all into stash
        $c->stash(%stash_tokens);
    });

    
    # ----------------------
    # Router
    # ----------------------
    my $r = $self->routes;

    # Home
    $r->get('/')->to('home#index');
    $r->get('/about-us')->to('home#about');
    $r->get('/before-you-go')->to('home#before_you_go');
    $r->any('/contact-us')->to('home#contact_us');
    $r->get('/enquiry')->to('home#get_enquiry');
    $r->post('/enquiry')->to('home#post_enquiry');
    $r->get('/faq')->to('home#faq');
    $r->get('/policies')->to('home#policies');
    $r->get('/search-results')->to('home#search_results');
    $r->get('/site-map')->to('home#site_map');
    $r->get('/state/:state')->to('home#state');
    $r->get('/sustainable-tourism')->to('home#sustainable_tourism');
    $r->get('/testimonials')->to('home#testimonials');
    $r->get('/travel-ideas')->to('home#travel_ideas');
    $r->get('/what-to-expect')->to('home#what_to_expect');
    $r->get('/why-travel_with_us')->to('home#why_travel_with_us');

    # Hotels
    $r->get('/hotel-categories')->to('hotels#show_hotel_categories');
    $r->get('/hand-picked-hotels')->to('hotels#show_hand_picked_hotels');

    # DESTINATIONS ROUTES
    
    # Ideas
    $r->get('/destinations/'.IDEAS.'/:destination/list')
        ->to('destinations#show_idea_list');
    $r->get('/destinations/'.IDEAS.'/:destination/:idea/:view')
        ->to('destinations#show_idea_detail');  

    # Tailor-made
    $r->get('/destinations/'.TAILOR.'/:destination/:view')
        ->to('destinations#show_tailor');

    # destinations/explore-by-region/kolkata-the-east/list
    # Regions
    $r->get('/destinations/'.REGIONS.'/:destination/list')
        ->to('destinations#show_region_list');

    $r->get('/destinations/'.REGIONS.'/:destination/:region/:view')
        ->to('destinations#show_region_detail');

    # States
    $r->get('/destinations/'.STATES.'/:destination/list')
        ->to('destinations#show_state_list');
    $r->get('/destinations/'.STATES.'/:destination/:state/:view')
        ->to('destinations#show_state_detail');

    # Themes
    $r->get('/destinations/'.THEMES.'/:destination/list')
        ->to('destinations#show_theme_list');
    $r->get('/destinations/'.THEMES.'/:destination/:theme/:view')
        ->to('destinations#show_theme_detail');

    
    $r->get('/destinations/:destination/:option/:view/:order/:region')
        ->to('itineraries#route_listing');

    $r->any('/plan-your-trip')->to('destinations#plan_your_trip');

    # My Account
    $r->get( '/my-account')->to('my_account#login');
    $r->post('/my-account/register')->to('my_account#register');
    $r->post('/my-account/mail-password')->to('my_account#mail_password');

    # Currency switcher
    $r->get('/currency/:currency' => sub ($c) {
        $c->session(currency => $c->param('currency'));
        $c->redirect_to($c->req->headers->referrer // '/');
    });

    # Images
    $r->get('/images/*filepath')->to('images#serve_image');

    # API
    $r->get('/api/ping')->to('api#ping');
    $r->get('/api/user/:id')->to('api#user_info');

    # Catch-all 404
    $r->any('/*whatever')->to(cb => sub ($c) {
        $c->render(template => '404', status => 404);
    });


    # ----- Debug helper -----
    # $self->dd($expect);  👈 this dumps & stops here
    $self->helper(dd => sub ($c, $var) {
      local $Data::Dumper::Terse  = 1;
      local $Data::Dumper::Indent = 1;
      my $dump = Dumper($var);
      $c->app->log->debug(Data::Dumper::Dumper($var));
      $c->render(text => "<pre>$dump</pre>");
      $c->finish;   # Stop request right after showing dump
    });

    $self->helper(dump_log => sub ($c, $msg, $var = undef) {
      local $Data::Dumper::Terse  = 1;
      local $Data::Dumper::Indent = 1;

      my $dump = $var ? Data::Dumper::Dumper($var) : '';
      my $full = $msg . ($dump ? "\n$dump" : '');

      # Log to file as usual
      $c->app->log->debug($full);

      # Store dump in stash for footer display (dev only)
      if ($c->app->mode eq 'development') {
        $c->stash->{_debug_dumps} //= [];
        push @{$c->stash->{_debug_dumps}}, $full;
      }
    });

    $self->helper(debug_footer => sub ($c, $msg) {
        push @{$c->stash->{debug_footer} ||= []}, $msg;
        $c->app->log->debug($msg);  # optional: also log to console/file
    });    

    $self->helper(session_currency => sub ($c) {
        my $cur = $c->session('currency') || 'USD';
        $c->stash(session_currency => $cur);
        return $cur;
    });

    # ----------------------
    # Test and benchmark Memcached (development only)
    # ----------------------
    if ($self->mode eq 'development') {
        $self->routes->get('/memcache/test' => sub ($c) {
            my $cache = $c->memcache;

            my $key   = 'travellers_palm_test';
            my $value = 'Hello from Memcached at ' . scalar localtime;

            # --- Basic functionality check
            $cache->set($key, $value, 60);
            my $fetched = $cache->get($key);

            my %basic = (
                stored  => $value,
                fetched => $fetched // 'undef',
                status  => (defined $fetched && $fetched eq $value) ? 'ok' : 'error'
            );

            # --- Performance benchmark
            my $count = 1000;
            my $prefix = 'bench_test_';
            my $start_set = [Time::HiRes::gettimeofday()];
            for my $i (1 .. $count) {
                $cache->set("${prefix}${i}", "value_$i", 60);
            }
            my $elapsed_set = Time::HiRes::tv_interval($start_set);

            my $start_get = [Time::HiRes::gettimeofday()];
            my $hits = 0;
            for my $i (1 .. $count) {
                my $v = $cache->get("${prefix}${i}");
                $hits++ if defined $v;
            }
            my $elapsed_get = Time::HiRes::tv_interval($start_get);

            my %bench = (
                count        => $count,
                set_time_s   => sprintf('%.4f', $elapsed_set),
                get_time_s   => sprintf('%.4f', $elapsed_get),
                set_per_sec  => sprintf('%.1f', $count / $elapsed_set),
                get_per_sec  => sprintf('%.1f', $count / $elapsed_get),
                hits         => $hits,
                hit_rate_pct => sprintf('%.1f', ($hits / $count) * 100),
            );

            return $c->render(json => {
                basic_check => \%basic,
                benchmark   => \%bench
            });
        });
    }
}


1;
