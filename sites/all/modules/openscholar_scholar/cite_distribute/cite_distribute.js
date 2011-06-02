// The following line will prevent a JavaScript error if this file is included and vertical tabs are disabled.
Drupal.verticalTabs = Drupal.verticalTabs || {};

Drupal.verticalTabs.cite_distribute_selections = function() {
  var vals = [];
  if ($('#edit-googlescholar-meta').attr('checked')) {
    vals.push(Drupal.t('Google Scholar'));
  }
  if ($('#edit-repec-meta').attr('checked')) {
    vals.push(Drupal.t('RePEc'));
  }
  // this will eventually have to generalize over each sword repo...
  if ($('#edit-sword-meta').attr('checked')) {
	    vals.push(Drupal.t('SWORD'));
	  }
  else {
    vals.push(Drupal.t(''));
  }
  if (vals.join(', ') == '') {
    return Drupal.t('None');
  }
  return vals.join(', ');
}