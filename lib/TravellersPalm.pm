package TravellersPalm;

use Cache::Memcached;
use Dotenv -load;
use Email::Sender::Transport::SMTP;
use Email::Stuffer;
use File::Spec;
use Mojo::Base 'Mojolicious', -signatures;
use Mojo::File 'path';
use Mojo::JSON qw(encode_json);
use Mojo::Log;
use POSIX qw(strftime);
use Sys::Hostname 'hostname';
use Term::ANSIColor;
use Time::HiRes qw(gettimeofday tv_interval);
use TravellersPalm::Constants qw(:all);
use TravellersPalm::Database::Connector qw(setup);


# Initialize once, globally
my $transport = Email::Sender::Transport::SMTP->new({
    host          => $ENV{EMAIL_HOST},
    port          => $ENV{EMAIL_PORT},
    sasl_username => $ENV{EMAIL_USER},
    sasl_password => $ENV{EMAIL_PASS},
    ssl           => $ENV{EMAIL_TLS} ? 1 : 0,
});

# Store in the app object so other modules can access
$app->attr(email_transport => sub { $transport });


sub startup ($self) {

    # 1. Load config, setup log
    # 2. Helpers
    # 3. Hooks
    # 4. Routes

    $self->log->format(sub {
        my ($time, $level, @lines) = @_;
        
        # Format timestamp in local timezone
        my $ts = strftime("%Y-%m-%d %H:%M:%S %Z", localtime($time));

        my %colors = (
            debug => 'cyan',
            info  => 'green',
            warn  => 'yellow',
            error => 'red',
            fatal => 'bright_red on_black',
        );
        my $color = $colors{$level} // 'white';

        my $msg = join('', @lines);
        $msg =~ s/^\s+|\s+$//g;

        return sprintf("[%s] [pid:%d] %s %s\n",
            $ts,
            $$,
            uc($level),
            $msg,
        );
    });
    
    # Set up the DB connector *immediately*
    $self->log->debug('Calling DB setup');
    TravellersPalm::Database::Connector->setup($self);

    # ----------------------
    # 1. Configuration and secrets
    # ----------------------

    my $config = $self->plugin('yaml_config' => {
        file      => 'config.yml',
        stash_key => 'conf',
        class     => 'YAML::XS',
    });

    $self->helper(config => sub { $config });
    $self->secrets($config->{secrets});
    $self->config($config);   

    # Create SMTP transport from config
    my $smtp_cfg = $config->{email}{smtp};
    my $transport = Email::Sender::Transport::SMTP->new($smtp_cfg);

    # Store it in app stash for global use
    $self->helper(email_transport => sub { $transport });

    # ----------------------
    #  Log setup
    # ----------------------
    my $log_conf = $self->config->{log} // {};
    $log_conf->{path}  //= path($self->home, 'log', 'travellers_palm.log')->to_string;
    $log_conf->{level} //= 'debug';

    my $log_path = path($log_conf->{path});
    $log_path->dirname->make_path;

    my $logger = Mojo::Log->new(
        path  => $log_conf->{path},
        level => $log_conf->{level},
    );

    $self->log($logger);

    #----------------------------------
    # Verify logging and paths
    #----------------------------------
    my $app_home = $self->home->to_string;
    $self->log->debug("App home directory: $app_home");
    $self->log->debug("Configured log path: $log_conf->{path}");
    $self->log->debug("Logging initialized at $log_conf->{path} (level=$log_conf->{level})");

    # Keep refs if needed later
    my $log_file = $log_path;
    my $log_dir  = $log_path->dirname;


    #----------------------------------
    # Memcached
    #----------------------------------

    my $memd_conf = $self->config->{memcached} // {};
    my $memd = Cache::Memcached->new({
        servers => $memd_conf->{servers} // ['127.0.0.1:11211'],
        compress_threshold => 10_000,
    });
    $self->helper(memcache => sub { $memd });


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
    # 2. Helpers
    # ----------------------

    $self->helper(dd => sub ($c, $var) {
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 1;
        my $dump = Dumper($var);
        $c->app->log->debug($dump);
        $c->render(text => "<pre>$dump</pre>");
        $c->finish;
    });

    $self->helper(debug_footer => sub ($c, $msg) {
        push @{$c->stash->{debug_footer} ||= []}, $msg;
        $c->app->log->debug($msg);
    });

    $self->helper(session_currency => sub ($c) {
        my $cur = $c->session('currency') // 'USD';
        $c->stash(session_currency => $cur);
        return $cur;
    });

    # ----- Debug helper -----
    $self->helper(dump_log => sub ($c, $msg, $var = undef) {
      my $full = $msg;
      $full .= "\n" . Dumper($var) if $var;
      $c->app->log->debug($full);
      push @{$c->stash->{_debug_dumps} ||= []}, $full if $c->app->mode eq 'development';

      local $Data::Dumper::Terse  = 1;
      local $Data::Dumper::Indent = 1;

      my $dump = $var ? Data::Dumper::Dumper($var) : '';

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

    # ----------------------
    # 3. Hooks
    # ----------------------
    $self->hook(before => sub ($c) {
        $c->session(currency => $c->session('currency') // 'EUR');
        $c->session(country  => $c->session('country')  // 'IN');
        $c->stash(session_currency => $c->session_currency);
    });

    $self->hook(before_dispatch => sub ($c) {
        my $date = strftime('%Y-%m-%d', localtime);

        my $current_log = $log_dir->child("travellers_palm.log.$date");
        rename $log_file, $current_log if -f $log_file && !-f $current_log;

        my $country = $c->stash('country') || $c->session('country') || 'india';
        $country = lc $country;
        $c->session(country => $country);
        $c->stash(country => $country);
    });

    $self->hook(after_dispatch => sub ($c) {
        my $route = $c->match && $c->match->endpoint;
        return unless $route && $route->can('pattern');

        # Try to get the route pattern as a human-readable string
        my $pattern;
        eval {
            $pattern = $route->pattern->uncompiled;  # <-- nicer string
        };
        $pattern //= "$route";  # fallback
    
        return if $pattern eq '(?^ups:^/(.+))';
    
        $c->app->log->debug("Matched route: $pattern");

        # Alert the admin
        my $status = $c->res->code // 200;
        return unless $status == 500;   # only trigger on server errors

        my $exception  = $c->stash('exception') || '(unknown error)';
        my $req        = $c->req;
        my $url        = $req->url->to_abs;
        my $method     = $req->method;
        my $ip         = $c->tx->remote_address;
        my $agent      = $req->headers->user_agent // '(no UA)';
        my $time       = scalar localtime;
        my $hostname   = hostname();

        # Render the email body from a template
        my $body = $c->render_to_string(
            template => 'mail/error_email',
            format   => 'html',
            handler  => 'tt',
            vars     => {
                url       => $url,
                method    => $method,
                ip        => $ip,
                agent     => $agent,
                time      => $time,
                host      => $hostname,
                exception => $exception,
                body      => $c->res->body,
            },
        );

        # Pull settings from config and env (with fallback defaults)
        my $from    = $self->config->{email}{error}{from}    // 'noreply@travellerspalm.com';
        my $subject = $self->config->{email}{error}{subject} // "[" . ($self->config->{appname} // 'TravellersPalm') . "] Error at $url";

        Email::Stuffer->from ($from)
                       ->to ($ENV{EMAIL_USER})
                       ->subject ($subject)
                       ->html_body($body)
                       ->transport($self->app->email_transport)
                       ->send;
    });

    $self->hook(around_dispatch => sub ($next, $c) {
        eval { $next->(); 1 } or do {
            my $error = $@ || 'Unknown error';
            $c->app->log->error("Dispatch error: $error");

            # Render 404 if it's a route-without-action type
            if ($error =~ /Route without action/) {
                return $c->render(
                    template => '4042',
                    message  => 'Sorry, that page does not exist.',
                    url      => $c->req->url->to_string,
                    status   => 404,
                );
            }

            # Otherwise render a generic 500
            return $c->render(
                template => '500',
                message  => 'An internal error occurred.',
                status   => 500,
            );
        };
    });


    $self->hook(before_render => sub ($c, $args) {
        my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
        $year += 1900;
        my $tokens = $c->app->config->{template_tokens} // {};
        my %stash_tokens = map { uc($_) => $tokens->{$_} } keys %$tokens;
        $stash_tokens{COUNTRY}  = $c->session('country');
        $stash_tokens{CURRENCY} = $c->session('currency');
        $stash_tokens{YEAR}     = $year;
        $c->stash(%stash_tokens);
    });

    

    # ----------------------
    # 4. Routes
    # ----------------------
    my $r = $self->routes;

    # Home
    $r->get('/')->to('home#index');
    $r->get('/about-us')->to('home#about');
    $r->get('/before-you-go')->to('home#before_you_go');
    $r->get('/contact-us')->to('home#contact_us');
    $r->get('/faq')->to('home#faq');
    $r->get('/policies')->to('home#policies');
    $r->get('/search-results')->to('home#search_results');
    $r->get('/sitemap')->to('home#site_map');
    $r->get('/state/:state')->to('home#state');
    $r->get('/sustainable-tourism')->to('home#sustainable_tourism');
    $r->get('/testimonials')->to('home#testimonials');
    $r->get('/travel-ideas')->to('home#travel_ideas');
    $r->get('/what-to-expect')->to('home#what_to_expect');
    $r->get('/why-travel-with-us')->to('home#why_travel_with_us');

    # Enquiry (GET + POST)
    $r->get('/enquiry')->to('home#get_enquiry');
    $r->post('/enquiry')->to('home#post_enquiry');

    # -----------------------------
    # Hotels routes
    # -----------------------------
    $r->get('/hotel-categories')->to('hotels#show_hotel_categories');
    $r->get('/hand-picked-hotels')->to('hotels#show_hand_picked_hotels');

    # -----------------------------
    # Itineraries routes
    # -----------------------------
    $r->get('/itineraries/:option')->to('itineraries#route_listing');
    $r->get('/itineraries/:option/:tour')->to('itineraries#route_itinerary');

 
    # -----------------------------
    # Destinations routes
    # -----------------------------
    
    $r->get('/destinations/:country/'.IDEAS.'/:destination/list')
        ->to('destinations#show_idea_list');
    $r->get('/destinations/:country/'.IDEAS.'/:destination/:idea/:view')
        ->to('destinations#show_idea_detail');  

    $r->get('/destinations/:country/'.TAILOR.'/list')
        ->to('itineraries#route_listing');
    $r->get('/destinations/:country/'.TAILOR.'/:destination/:view')
        ->to('itineraries#route_itinerary');

    $r->get('/destinations/:country/regions')
        ->to('destinations#regions');
    $r->get('/destinations/:country/'.REGIONS.'/:destination/:list')
        ->to('destinations#show_region_list');
    $r->get('/destinations/:country/'.REGIONS.'/:destination/:region/:view')
        ->to('destinations#show_region_detail');

    $r->get('/destinations/india/states')
        ->to('destinations#states');
    $r->get('/destinations/india/'.STATES.'/:destination/:list')
        ->to('destinations#show_state_list');
    $r->get('/destinations/india/'.STATES.'/:destination/:state/:view')
        ->to('destinations#show_state_detail');

    $r->get('/destinations/:country/themes')
        ->to('destinations#themes');
    $r->get('/destinations/:country/'.THEMES.'/:destination/:list')
        ->to('destinations#show_theme_list');
    $r->get('/destinations/:country/'.THEMES.'/:destination/:theme/:view')
        ->to('destinations#show_theme_detail');

    $r->get('/destinations/:country/:option/:view/:order/:region')
        ->to('itineraries#route_listing');

    # redirect
    $r->get('/destinations/:destination')->to(cb => sub ($c) {
        my $country = $c->session('country') || 'india';
        my $dest    = $c->stash('destination');
        return $c->redirect_to("/destinations/$country/$dest");
    });

    $r->any('/plan-your-trip')->to('destinations#plan_your_trip');

    # -----------------------------
    # My Account routes
    # -----------------------------
    $r->get('/login')->to('my_account#login');
    $r->post('/register')->to('my_account#register');
    $r->post('/mail-password')->to('my_account#mail_password');

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

    # -----------------------------
    # Catch-all fallback (404)
    # -----------------------------
    # Catch-all route for anything not handled explicitly
    $r->any('*')->to(cb => sub ($c) {
        $c->render(
            template => '404',
            message  => 'The page you are looking for does not exist.',
            url      => $c->req->url->to_string,
            status   => 404,
        );
    });

}

1;