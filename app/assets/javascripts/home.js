with (scope('Home', 'App')) {

  route('#not_found', function() {
    render(
      h1("Oops! That page wasn't found!"),
      p('If you know what you were expecting, please send us an email: ', a({ href: 'mailto:support@santim.vn' }, 'support@santim.vn'))
    );
  });

  route('#', function() {
    // render nothing, then hide the content for now... we're using before-content!!
    render('');
    hide('content');

    // make the box smaller if logged in
    if (logged_in()) add_class(Home.top_box, 'small');

    render({ into: 'before-content' },
      section({ id: 'homepage' },
        div({ id: 'card-rows-container' })
      )
    );
  });

  define('cards_row', function(title, cards_data, card_template_method) {
    var cards_row = div({ 'class': 'card-row', id: 'fundraiser-cards-row' },
      cards_data.map(function(card) { return card_template_method(card) })
    );

    // need to insert blank cards to fill space?
    if (cards_data.length % cards_per_page != 0) {
      // build a fake card, get its width
      var placeholder = div({ style: 'width: 238px;' });
      for (var i=0; i<(cards_per_page - cards_data.length % cards_per_page); i++) {
        cards_row.appendChild(div({ 'class': 'card', style: 'opacity: 0; margin-right: 10px; height: 0;' }));
      }
    }

    // add pagination data to row element
    cards_row['data-page-count'] = Math.ceil(cards_data.length / cards_per_page);
    cards_row['data-page-index'] = 0;

    return [
      card_row_header(title, cards_row, { show_nav_buttons: cards_data.length > cards_per_page }),
      cards_row
    ];
  });

  define('card_row_header', function(title, row_element, options) {
    options = options || {};
    options.show_nav_buttons = options.show_nav_buttons || false;

    var previous_button = div({ 'class': 'card-nav-button previous disabled' }, div('←')),
        next_button     = div({ 'class': 'card-nav-button next' }, div('→'));

    previous_button.addEventListener('click', curry(card_nav_button_listener, row_element, next_button));
    next_button.addEventListener('click',     curry(card_nav_button_listener, row_element, previous_button));

    return div({ 'class': 'card-row header' },
      options.show_nav_buttons && previous_button,
      div({ 'class': 'card-nav-title' }, title),
      options.show_nav_buttons && next_button
    );
  });
}
