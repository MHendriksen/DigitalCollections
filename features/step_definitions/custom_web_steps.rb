Then /^I should (not )?see element "([^"]*)"$/ do |yesno, selector|
  if yesno == 'not '
    if (elements = page.all(selector)).size > 0
      elements.each do |element|
        element.visible?.should be_false
      end
    else
      page.should_not have_css(selector)  
    end
  else
    page.should have_css(selector)
  end
end

When /^I fill in "([^"]*)" attachment "([^"]*)" with "([^"]*)"$/ do |attachment_id, index, values|
  values = values.split('/')
  attachments = page.all("##{attachment_id} .attachment")
  attachments[index.to_i - 1].all('input[type=text]').each_with_index do |input, i|
    input.set(values[i]) unless values[i].blank?
  end
end

Then /^I should (not )?really see element "([^"]*)"$/ do |yesno, selector|
  page.all(selector).each do |element|
    if yesno == 'not '
      element.visible?.should be_false
    else
      element.visible?.should be_true
    end
  end
end

When /^I select "([^"]*)" from the collections selector$/ do |collections|
  collections = collections.split('/').map{|c| Collection.find_by_name(c).id}
  page.find('form.kor_form a img[alt=Pen]').click
  dialog = page.all(:css, '.ui-dialog').last
  dialog.all(:css, 'input[type=checkbox]').each do |input|
    input.click unless collections.include?(input.value.to_i)
  end
  dialog.all(:css, 'button').last.click
end

Then /^I should see "([^"]*)" before "([^"]*)"$/ do |preceeding, following|
  page.body.should match(/#{preceeding}.*#{following}/m)
end

Then /^I hover element "([^\"]*)"$/ do |selector|
  page.execute_script("jQuery('#{selector}').mouseover()")
end

Then /^I should see an input with the current date$/ do
  expect(page).to have_field("user_group_name", :with => Time.now.strftime("%d.%m.%Y"))
end

Then /^I should see the hidden element "([^"]*)"$/ do |selector|
  page.all(selector).any? do |element|
    !element.visible?
  end.should be_true
end

When /^(?:|I )unselect "([^"]*)" from "([^"]*)"(?: within "([^"]*)")?$/ do |value, field, selector|
  with_scope(selector) do
    unselect(value, :from => field)
  end
end

When /^I fill in "([^"]*)" with "([^"]*)" and select term "([^"]*)"$/ do |field, value, pattern|
  step "I fill in \"#{field}\" with \"#{value}\""
  step "I select \"Begriff '#{pattern}'\" from the autocomplete"
end

When /^I fill in "([^"]*)" with "([^"]*)" and select tag "([^"]*)"$/ do |field, value, pattern|
  step "I fill in \"#{field}\" with \"#{value}\""
  step "I select \"Tag: #{pattern}\" from the autocomplete"
end

When /^I select "([^"]*)" from the autocomplete$/ do |pattern|
  t = Time.now
  while Time.now - t < 5.seconds && !page.all('li.ui-menu-item a').to_a.find{|a| a.text.match Regexp.new(pattern)}
    sleep 0.2
  end

  page.all('li.ui-menu-item a').to_a.find do |anker|
    anker.text.match Regexp.new(pattern)
  end.click
end

When /^I press the "([^"]*)" key$/ do |key|
  key = case
    when 'enter' then 13
    else
      raise "undefined key #{key}"
  end

  page.execute_script("
    function trigger_key(k) {
      var event = $.Event('keypress');
      event.which = k;
      $(':focus').trigger(event);
    }
    trigger_key('#{key}');
  ")
end

When /^I send the credential "([^\"]*)"$/ do |attributes|
  fields = attributes.split(',').map{|a| a.split(':')}
  attributes = {}
  fields.each{|f| attributes[f.first.to_sym] = f.last}
  Capybara.current_session.driver.send :post, '/credentials', :credential => attributes
  Capybara.current_session.driver.browser.follow_redirect!
end

When /^I send the delete request for "([^\"]*)" "([^\"]*)"$/ do |object_type, object_name|
  object = object_type.classify.constantize.find_by_name(object_name)
  Capybara.current_session.driver.send :delete, send(object_type + '_path', object)
  Capybara.current_session.driver.browser.follow_redirect!
end

When /^I send the mark request for entity "([^"]*)"$/ do |entity|
  entity = Entity.find_by_name(entity)
  Capybara.current_session.driver.send :delete, put_in_clipboard_path(:id => entity.id, :mark => 'mark')
  if page.status_code >= 300 && page.status_code < 400
    Capybara.current_session.driver.browser.follow_redirect!
  end
end

When /^I send the mark as current request for entity "([^"]*)"$/ do |entity|
  entity = Entity.find_by_name(entity)
  Capybara.current_session.driver.send :delete, mark_as_current_path(:id => entity.id), {}, {'HTTP_REFERER' => '/'}
  if page.status_code >= 300 && page.status_code < 400
    Capybara.current_session.driver.browser.follow_redirect!
  end
end

When /^I send a "([^\"]*)" request to "([^\"]*)" with params "([^\"]*)"$/ do |method, url, params|
  Capybara.current_session.driver.send method.downcase.to_sym, url, eval(params)
  if page.status_code >= 300 && page.status_code < 400
    Capybara.current_session.driver.browser.follow_redirect!
  end
end

When /^I send a "([^\"]*)" request to path "([^\"]*)" with params "([^\"]*)"$/ do |method, path, params|
  Capybara.current_session.driver.send method.downcase.to_sym, path_to(path), eval(params)
  if page.status_code >= 300 && page.status_code < 400
    Capybara.current_session.driver.browser.follow_redirect!
  end
end

Then /^I should get access "([^\"]*)"$/ do |access|
  step "I should not be on the denied page" if access == 'yes'
  step "I should be on the denied page"   if access == 'no'
end

When /^I ignore the next confirmation box$/ do
  page.evaluate_script('window.confirm = function() { return true; }')
end

When /^I click(?: on)? element "([^\"]+)"$/ do |selector|
  page.find(selector).click
end

When /^I follow the delete link$/ do
  step "I ignore the next confirmation box"
  click_link 'X'
end

When /^I click on "([^\"]*)"$/ do |selector|
  page.find(selector).click
end

Then /^(?:|I )should not be on (.+)$/ do |page_name|
  current_path = URI.parse(current_url).path
  if current_path.respond_to? :should
    current_path.should_not eql(path_to(page_name))
  else
    assert_not_equal path_to(page_name), current_path
  end
end

Then /^I should have access: (yes|no)$/ do |yesno|
  if yesno == 'yes'
    page.should_not have_content('Zugriff wurde verweigert')
  else
    page.should have_content('Zugriff wurde verweigert')
  end
end

When /I debug/ do
  debugger
  x = 15
end

When /^I wait for "([^"]*)" seconds?$/ do |num|
  sleep num.to_f
end

When /^I fill in element "([^"]*)" with index "([^"]*)" with "([^"]*)"$/ do |field, index, value|
  page.all(field)[index.to_i].set value
end

Then /^the element "([^"]*)" with index "([^"]*)" should contain "([^"]*)"$/ do |field, index, value|
  page.all(field)[index.to_i].value.should match(Regexp.new value)
end

When /^I fill in "([^"]*)" with harmful code$/ do |field_name|
  harmful_code = "\\#\\{system 'touch tmp/harmful.txt'\\}"
  step "I fill in \"#{field_name}\" with \"#{harmful_code}\""
end

Then /^the harmful code should not have been executed$/ do
  File.exists?("#{Rails.root}/tmp/harmful.txt").should be_false
end

When /^I click on the player link$/ do
  page.find('.viewer .kor_medium_frame a').click
end

Then /^I should see the video player$/ do
  page.should have_selector('.video-js')
end
