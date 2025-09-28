<?php 
$errors = '';
$myemail = 'info@travellers-palm.com';//<-----Put Your email address here.
if(empty($_POST['name'])  || 
   empty($_POST['email']) || 
   empty($_POST['message']))
{
    $errors .= "Error: Name, Email and Message fields are required";
}

$name = $_POST['name']; 
$email_address = $_POST['email']; 
$subject = isset($_POST['subject']) ? $_POST['subject'] : "";
$message = $_POST['message'];
$website = isset($_POST['website']) ? $_POST['website'] : "";

if (!preg_match(
"/^[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,3})$/i", 
$email_address))
{
    $errors .= "<br />Error: Invalid email address";
}

if( empty($errors))
{
    $to = $myemail; 
    $email_subject = "Contact form submission" . (empty($subject) ? "" : ": " . $subject);
    $email_body = "You have received a new message. ".
    " Here are the details:\n\nName: $name \nEmail: $email_address " . (empty($website) ? "" : "\nWebsite: " . $website) . "\nMessage: \n\n$message"; 
    
    $headers = "From: $myemail\n"; 
    $headers .= "Reply-To: $email_address";
    
    mail($to,$email_subject,$email_body,$headers);

    $success_msg = "Your message successfully sent!";
} 
?>

[% INCLUDE layouts/header.tt %] 
        <div class="page-title-container">
            <div class="container">
                <div class="page-title pull-left">
                    <h2 class="entry-title">Contact Us</h2>
                </div>
                <ul class="breadcrumbs pull-right">
                    <li><a href="[% request.uri_base %]/home">HOME</a></li>
                    <li class="active">Contact Us</li>
                </ul>
            </div>
        </div>

        <section id="content">
            <div class="container">
                <div id="main">
                    <div class="travelo-google-map block"></div>
                    <div class="row">
                        <div class="col-sm-4 col-md-3">
                            <div class="travelo-box contact-us-box">
                                <h4>Contact us</h4>
                                <ul class="contact-address">
                                    <li class="address">
                                        <i class="soap-icon-address circle"></i>
                                        <h5 class="title">Address</h5>
                                        <p>2/286 Boa Viagem Road, Naikavaddo</p>
                                        <p>Calangute, Goa, India.</p>
                                    </li>
                                    <li class="phone">
                                        <i class="soap-icon-phone circle"></i>
                                        <h5 class="title">Phone</h5>
                                        <p>Local: +91 832 2276941</p>
                                        <p>Mobile: +91 98221 22221</p>
                                    </li>
                                    <li class="email">
                                        <i class="soap-icon-message circle"></i>
                                        <h5 class="title">Email</h5>
                                        <p>info@travellers-pam.com</p>
                                        <p>www.travellers-palm.com</p>
                                    </li>
                                </ul>
                                <ul class="social-icons full-width">
                                    <li><a href="#" data-toggle="tooltip" title="Twitter"><i class="soap-icon-twitter"></i></a></li>
                                    <li><a href="#" data-toggle="tooltip" title="GooglePlus"><i class="soap-icon-googleplus"></i></a></li>
                                    <li><a href="#" data-toggle="tooltip" title="Facebook"><i class="soap-icon-facebook"></i></a></li>
                                    <li><a href="#" data-toggle="tooltip" title="Linkedin"><i class="soap-icon-linkedin"></i></a></li>
                                    <li><a href="#" data-toggle="tooltip" title="Vimeo"><i class="soap-icon-vimeo"></i></a></li>
                                </ul>
                            </div>
                        </div>
                        <div class="col-sm-8 col-md-9">
                            <div class="travelo-box">
                                <form class="contact-form" action="contact-us-handler.php" method="post">
                                    <h4 class="box-title">Send us a Message</h4>
                                    <div class="row form-group">
                                        <div class="col-xs-6">
                                            <label>Your Name</label>
                                            <input type="text" name="name" class="input-text full-width">
                                        </div>
                                        <div class="col-xs-6">
                                            <label>Your Email</label>
                                            <input type="text" name="email" class="input-text full-width">
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        <label>Your Message</label>
                                        <textarea name="message" rows="6" class="input-text full-width" placeholder="write message here"></textarea>
                                    </div>
                                    <button type="submit" class="btn-large full-width">SEND MESSAGE</button>
                                </form>
                            </div>
                        </div>
                    </div>

                </div>
            </div>
        </section>
        
          [% INCLUDE layouts/footer.tt %] 
    </div>


    <!-- Javascript -->
    <script type="text/javascript" src="[% request.uri_base %]/js/jquery-1.11.1.min.js"></script>
    <script type="text/javascript" src="[% request.uri_base %]/js/jquery.noconflict.js"></script>
    <script type="text/javascript" src="[% request.uri_base %]/js/modernizr.2.7.1.min.js"></script>
    <script type="text/javascript" src="[% request.uri_base %]/js/jquery-migrate-1.2.1.min.js"></script>
    <script type="text/javascript" src="j[% request.uri_base %]/s/jquery.placeholder.js"></script>
    <script type="text/javascript" src="[% request.uri_base %]/js/jquery-ui.1.10.4.min.js"></script>
    
    <!-- Twitter Bootstrap -->
    <script type="text/javascript" src="[% request.uri_base %]/js/bootstrap.js"></script>

    <!-- Google Map Api -->
    <script type='text/javascript' src="[% request.uri_base %]/http://maps.google.com/maps/api/js?sensor=false&amp;language=en"></script>
    <script type="text/javascript" src="[% request.uri_base %]/js/gmap3.min.js"></script>
    
    <!-- parallax -->
    <script type="text/javascript" src="[% request.uri_base %]/js/jquery.stellar.min.js"></script>
    
    <!-- waypoint -->
    <script type="text/javascript" src="[% request.uri_base %]/js/waypoints.min.js"></script>

    <!-- load page Javascript -->
    <script type="text/javascript" src="[% request.uri_base %]/js/theme-scripts.js"></script>
    <script type="text/javascript" src="[% request.uri_base %]/js/scripts.js"></script>

    <script type="text/javascript">
        tjq(".travelo-google-map").gmap3({
            map: {
                options: {
                    center: [15.537055, 73.771990],
                    zoom: 15
                }
            },
            marker:{
                values: [
                    {latLng:[15.537055, 73.771990], data:"Travellers-Palm"}

                ],
                options: {
                    draggable: false
                },
            }
        });
    </script>
</body>
</html>

