with (scope('Header','App')) {
  // reload the signin buttons on every page load, so that they have the correct redirect URl
  with (scope('App')) { after_filter(function() { !logged_in() && reload_signin_buttons() }) }

  define('create', function() {
    if (!logged_in()) {
      Header.signin_buttons = div({ id: 'signin-buttons' });
    }

    var header_element = header(
      section(
        a({ 'class': 'santim-logo', href: '#' },
          img({ src: 'images/logo.png' }),
          Header.global_social_buttons
        ),


        div({ style: 'float: right; margin-top: 15px;' },
          // logged in? show the user nav dropdown
          logged_in() && UserNav.create,

          // not logged in? show the signin buttons!
          !logged_in() && Header.signin_buttons
        )
      )
    );

    //reload_social_buttons();

    return header_element;
  });

  define('reload_social_buttons', function() {
    render({ into: Header.global_social_buttons },
      ul(
        li(Twitter.follow_button({
          'data-count':             'none',
          'data-show-screen-name':  false
        })),

        li(GooglePlus.like_button({
          'data-annotation': 'none'
        })),

        li(Facebook.like_button({
          'data-href': 'https://www.santim.vn'
        }))
      )
    );

    Twitter.process_elements();
    GooglePlus.process_elements();
    Facebook.process_elements();
  });

  define('reload_signin_buttons', function() {
    render({ into: Header.signin_buttons },
      span('Sign In with:'),
      ul(
        li(a({ href: Facebook.auth_url() }, img({ src: 'images/facebook.png' }))),
        li(a({ href: Twitter.auth_url() },  img({ src: 'images/twitter.png' }))),
        li(a({ href: '#signin/email' },     img({ src: 'images/email.png' })))
      )
    );
  });
}