with (scope('ST')) {

  define('api_host', 'http://localhost:3000/');
  define('www_host', document.location.href.split('#')[0]);

  // parse arguments: url, [http_method], [params], [callback]
  define('api', function() {
    var args = Array.prototype.slice.call(arguments);

    var options = {
      url:       api_host + args.shift().replace(/^\//,''),
      method:    typeof(args[0]) == 'string' ? args.shift() : 'GET',
      params:    typeof(args[0]) == 'object' ? args.shift() : {},
      callback:  typeof(args[0]) == 'function' ? args.shift() : function(){},
      non_auth_callback:  typeof(args[0]) == 'function' ? args.shift() : null
    };

    // add in our access token
    options.params.access_token = Storage.get('access_token');

    // reload the page if they're not authorized
    var callback = options.callback;
    options.callback = function(response) {
      if (response && response.meta && parseInt(response.meta.status) == 401) {
        Storage.remove('access_token');
        if (options.non_auth_callback) options.non_auth_callback(response);
        else if (scope.instance.App.unauthorized_callback) scope.instance.App.unauthorized_callback(options);
        else set_route('#');
      } else {
        // turn error message into string, or use default
        if (!response.meta.success) {
          if (!response.data.error) {
            response.data.error = "Unexpected error";
          } else if (response.data.error.push) {
            response.data.error = response.data.error.join(', ');
          }
        }

        callback.call(this, response);
      }
    };

    JSONP.get(options);
  });

  define('login', function(params, callback) {
    api('/user/login', 'POST', params, callback);
  });

  define('logout', function() {
    Storage.clear({ except: ['environment'] });
    set_route('#', { reload_page: true });
  });

  define('user_info', function(callback) {
    api('/user', callback);
  });

  define('set_access_token', function(data) {
    if (typeof(data) == 'string') {
      Storage.set('access_token', data);
      ST.set_cached_user_info(null);
    } else {
      Storage.set('access_token', data.access_token);
      ST.set_cached_user_info(data);
    }
  });

  define('get_cached_user_info', function(callback) {
    if (Storage.get('user_info')) {
      callback(parsed_user_info());
    } else {
      user_info(function(response) {
        if (response.meta.success) {
          set_cached_user_info(response.data);
          callback(response.data);
        }
      });
    }
  });

  define('set_cached_user_info', function(hash) {
    hash ? Storage.set('user_info', JSON.stringify(hash)) : Storage.remove('user_info');
  });

  define('parsed_user_info', function() {
    try {
      return JSON.parse(Storage.get('user_info'))
    } catch(e) {
      console.log("ERROR PARSING USER_INFO JSON:", Storage.get('user_info'));
      return {};
    }
  });

  define('basic_user_info', function(callback) {
    api('/user', 'GET', { basic: true }, callback);
  });

  define('create_account', function(data, callback) {
    api('/user', 'POST', data, callback);
  });

  define('update_account', function(data, callback) {
    api('/user', 'PUT', data, callback);
  });

  define('change_password', function(data, callback) {
    api('/user/change_password', 'POST', data, callback);
  });

  define('reset_password', function(data, callback) {
    api('/user/reset_password', 'POST', data, callback);
  });

  define('request_password_reset', function(data, callback) {
    api('/user/request_password_reset', 'POST', data, callback);
  });

  define('search', function(query, callback) {
    api('/search', 'POST', { query: query }, callback);
  });

  define('make_payment', function(data, error_callback) {
    var callback = function(response) {
      if (response.meta.success) {
        if (data.payment_method == 'personal') ST.set_cached_user_info(null);
        set_route(response.data.redirect_url);
      } else {
        error_callback(response.data.error);
      }
    };

    var non_auth_callback = function() {
      Storage.set('_redirect_to_after_login', data.postauth_url);
      set_route('#signin');
    };

    api('/payments', 'POST', data, callback, non_auth_callback);
  });

}
