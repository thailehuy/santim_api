with (scope('UserNav', 'App')) {
  define('create', function() {
    UserNav._wrapper = div({ id: 'user-nav' });
    UserNav._flyout = div({ id: 'user-nav-flyout-wrapper' });
    UserNav.reload();
    return UserNav._wrapper;
  });

  define('reload', function() {
    UserNav._wrapper.removeEventListener('mouseover', user_nav_flyout_mouseover);
    UserNav._wrapper.removeEventListener('mouseout',  user_nav_flyout_mouseout);

    render({ into: UserNav._wrapper }, div({ style: "padding: 5px; color: black;" }, 'Loading...'));

    ST.user_info(function(response) {
      var user = response.data;

      render({ into: UserNav._flyout },
        ul(
          li(a({ href: '#account/create_fundraiser' }, 'Create Fundraiser')),
          li(a({ href: '#account/fundraisers' },       'Fundraisers')),
          li(a({ href: '#contributions' },             'Contributions')),
          li(a({ href: '#solutions' },                 'Solutions')),
          li(a({ href: '#account' },                   'Account')),
          li(a({ href: ST.logout },          'Logout'))
        )
      );

      render({ into: UserNav._wrapper },
        div({ id: 'btn' },
          a({ href: user.frontend_path },
            img({ src: user.image_url }),
            span(user.display_name)
          )
        ),
        UserNav._flyout
      );

      // update the width of the flyout
      UserNav._flyout.style.width = UserNav._wrapper.offsetWidth+'px';

      UserNav._wrapper.addEventListener('mouseover', user_nav_flyout_mouseover);
      UserNav._wrapper.addEventListener('mouseout',  user_nav_flyout_mouseout);
    });
  });

  // User nav flyout events
  define('user_nav_flyout_mouseover', function() {
    add_class(this, 'active');

    if (this.usernav_timeout) {
      clearTimeout(this.usernav_timeout);
      delete this.usernav_timeout;
    }
  });

  define('user_nav_flyout_mouseout', function(e) {
    var user_nav = this;
    if (this.usernav_timeout) clearTimeout(this.usernav_timeout);
    this.usernav_timeout = setTimeout(function() {
      remove_class(user_nav, 'active');
    }, 250);
  });
}