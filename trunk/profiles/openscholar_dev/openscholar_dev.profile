<?php
// $Id$

/**
 * Implementation of hook_profile_details().
 */
function openscholar_dev_profile_details() {
  return array(
    'name' => 'openscholar_dev',
    'description' => 'openscholar_dev project by IQSS at Harvard University'
  );
}

/**
 * Implementation of hook_profile_modules().
 */
function openscholar_dev_profile_modules() {
  return array(
    'block',
    'blog',
    'book',
    'comment',
    'contact',
    'filter',
    'help',
    'menu',
    'node',
    'system',
    'search',
    'user',
    'path',
    'php',
    'taxonomy',
    'upload',
  );
}

/**
 * Returns an array list of core contributed modules.
 */
function _openscholar_dev_core_modules() {
 $contrib_modules = array(
  // sites/all/contrib
    'activity',
    'addthis',
    'advanced_help',
    'calendar',
    'litecal',
    'context',
    'context_contrib',
    'content_profile',
    'content_profile_registration',
    'context_ui',
    'ctools',
    'data',
    'data_node',
    'data_ui',
    'dialog',
    'feeds',
    'feeds_defaults',
    'filefield_paths',
    'file_aliases',
    'features',
    'flag',
    'imageapi',
    'imageapi_gd',
    'itweak_upload',
    'jquery_ui',
    'jquery_update',
    'lightbox2',
    'lucene_api',
    'mollom',
    'og',
    'og_access',
    'og_views',
    'og_vocab',
    'og_actions',
    'override_node_options',
    'menu_node',
    'pathauto',
    'permissions_api',
    'purl',
    'spaces',
    'spaces_og',
    'stringoverrides',
    'token',
    'trigger',
    'transliteration',
    'twitter_pull',
    'ucreate',
    'ucreate_og',
    'views',
    'views_bulk_operations',
    'views_ui',
    'views_export',
    'views_attach',
    'vertical_tabs',
    'wysiwyg',
  

  //cck
    'content',
    'content_copy',
    'diff',
    'date_timezone',
    'date_api',
    'date',
    'date_popup',
    'filefield',
    'fieldgroup',
    'imagecache',
    'imagecache_ui',
    'imagefield',
    'imagefield_crop',
    'link',
    'text',
    'number',
    'nodereference',
    'nodereference_url',
    'optionwidgets',


  // development
    'admin_menu',
    'devel',
    'devel_generate',
    'install_profile_api',
    'schema',
    'strongarm',
  );
  
  return $contrib_modules;
}

/**
 * Returns an array list of dsi modules.
 */
function _openscholar_dev_scholar_modules() {
  return array(
    'vsite',
    'scholar',
    'vsite_content',
    'vsite_domain',
    'scholar_events',
    'vsite_ga',
    'vsite_layout',
    'vsite_menus',
    'vsite_design',
    'vsite_users',
    'vsite_taxonomy',
    'vsitehelp',
    'vsite_news',
    'vsite_support',
    'vsite_widgets',
    'vsite_generic_settings',
    
  // scholar specific
    'biblio',
    'auto_nodetitle',

  //IQSS Specific
    'iqss_scholar',
  
    'cp',
    //'cp_node_forms',
    'scholarboot',
    'bkn',
    'cite_distribute',
   // 'cs_meta',
    'repec_meta',
    'googlescholar_meta',
    'dyntextfield',
    'scholarregister',
    'iqss_project',

    // features
    'scholar_dvn',
    'scholar_biocv',
    'scholar_links',
    'scholar_blog',
    'scholar_book',
    'scholar_announcements',
    'scholar_classes',
    'scholar_image_gallery',
    'scholar_publications',
    'scholar_software',
    'scholar_pages',
    'scholar_reader',
    'scholar_front',
    'scholar_profiles',
  );
}

/**
 * Implementation of hook_profile_task_list().
 */
function openscholar_dev_profile_task_list() {
  $tasks = array(
    'openscholar-configure' => st('openscholar  configuration'),
  );
  return $tasks;
}

/**
 * Implementation of hook_profile_tasks().
 */
function openscholar_dev_profile_tasks(&$task, $url) {

  $output = '';

  if ($task == 'profile') {
    $modules = _openscholar_dev_core_modules();
    $modules = array_merge($modules, _openscholar_dev_scholar_modules());

    $files = module_rebuild_cache();
    $operations = array();
    foreach ($modules as $module) {
      $operations[] = array('_install_module_batch', array($module, $files[$module]->info['name']));
    }
    $batch = array(
    'operations' => $operations,
    'finished' => '_openscholar_dev_profile_batch_finished',
    'title' => st('Installing @drupal', array('@drupal' => drupal_install_profile_name())),
    'error_message' => st('The installation has encountered an error.'),
    );
    // Start a batch, switch to 'profile-install-batch' task. We need to
    // set the variable here, because batch_process() redirects.
    variable_set('install_task', 'profile-install-batch');
    batch_set($batch);
    batch_process($url, $url);
  }

  // Run additional configuration tasks
  // @todo Review all the cache/rebuild options at the end, some of them may not be needed
  if ($task == 'openscholar-configure') {
    install_include(_openscholar_dev_core_modules());
    // create roles
    _openscholar_dev_create_roles();

    // configure wisywig/tinymce
    _openscholar_dev_wysiwyg_config();
    
    /*
    // Set a default footer message.
    variable_set('site_footer', '&copy; 2009 '. l('IQSS', 'http://www.iq.harvard.edu', array('absolute' => TRUE)));
    */

    // Rebuild key tables/caches
    menu_rebuild();
    module_rebuild_cache(); // Detects the newly added bootstrap modules
    node_access_rebuild();
    drupal_get_schema('system', TRUE); // Clear schema DB cache
    drupal_flush_all_caches();
    db_query("UPDATE {blocks} SET status = 0, region = ''"); // disable all DB blocks

    //features_rebuild();

    // enable the themes
    _openscholar_dev_enable_themes();

    variable_set('scholar_content_type', 'vsite');
    // set default to america/new yourk
    variable_set(date_default_timezone_name, "America/New_York");

    //_scholar_filefield_paths_config();
    _openscholar_dev_configure_biblio();

    // Get out of this batch and let the installer continue
    $task = 'profile-finished';
  }
  return $output;
}

/**
 * Finished callback for the modules install batch.
 *
 * Advance installer task to language import.
 */
function _openscholar_dev_profile_batch_finished($success, $results) {
  variable_set('install_task', 'openscholar-configure');
}

/**
 * enable a couple of themes
 */
function _openscholar_dev_enable_themes(){
  
  // the default theme is the project theme
  install_default_theme('scholar_project');
  
  $themes = array(
    'zen',
    'cp_theme',
    'scholar_base',
    'scholar_project',
    'scholar_theme_01',
    'scholar_theme_02',
    'scholar_theme_03',
    'scholar_theme_04',
    'scholar_theme_05',
    'scholar_theme_06',
    'scholar_theme_07',
    'scholar_theme_08',
    'scholar_theme_09',
    'scholar_theme_10',
    'scholar_theme_11',
    'scholar_theme_12'
  );
  
  //enable the themes
  install_enable_theme($themes);
	
  // disable all DB blocks
  db_query("UPDATE {blocks} SET status = 0, region = ''");
}

////////////////
// PRIVATE CONFIG FUNCTIONS
////////////////

/**
 *  Change the biblio Config
 *  TODO: permissions
 */
function _openscholar_dev_configure_biblio(){
  $s_common_string = <<<COMMON
a:4:{s:7:"storage";N;s:9:"submitted";b:1;s:6:"values";a:6:{s:15:"configured_flds";a:52:{i:15;a:4:{s:5:"title";s:19:"Year of Publication";s:4:"hint";s:33:"Enter YYYY, Submitted or In Press";s:6:"weight";s:3:"-45";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";s:8:"required";s:12:"autocomplete";i:0;}}i:1;a:5:{s:5:"title";s:7:"Authors";s:4:"hint";s:0:"";s:6:"weight";s:1:"2";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";s:8:"required";s:12:"autocomplete";s:12:"autocomplete";}s:9:"auth_type";a:18:{i:1;s:1:"1";i:2;s:1:"2";i:3;s:1:"3";i:4;s:1:"4";i:5;s:1:"5";i:10;s:2:"10";i:11;s:2:"11";i:12;s:2:"12";i:13;s:2:"13";i:14;s:2:"14";i:15;s:2:"15";i:16;s:2:"16";i:17;s:2:"17";i:18;s:2:"18";i:19;s:2:"19";i:20;s:2:"20";i:21;s:2:"21";i:22;s:2:"22";}}i:2;a:5:{s:5:"title";s:17:"Secondary Authors";s:4:"hint";s:0:"";s:6:"weight";s:1:"2";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:9:"auth_type";a:1:{i:2;s:1:"2";}}i:3;a:5:{s:5:"title";s:16:"Tertiary Authors";s:4:"hint";s:0:"";s:6:"weight";s:1:"3";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:9:"auth_type";a:1:{i:3;s:1:"3";}}i:4;a:5:{s:5:"title";s:18:"Subsidiary Authors";s:4:"hint";s:0:"";s:6:"weight";s:1:"4";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:9:"auth_type";a:1:{i:4;s:1:"4";}}i:5;a:5:{s:5:"title";s:17:"Corporate Authors";s:4:"hint";s:0:"";s:6:"weight";s:1:"5";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}s:9:"auth_type";a:1:{i:5;s:1:"5";}}i:6;a:4:{s:5:"title";s:15:"Secondary Title";s:4:"hint";s:0:"";s:6:"weight";s:2:"12";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:7;a:4:{s:5:"title";s:14:"Tertiary Title";s:4:"hint";s:0:"";s:6:"weight";s:2:"13";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:17;a:4:{s:5:"title";s:6:"Volume";s:4:"hint";s:0:"";s:6:"weight";s:2:"14";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:37;a:4:{s:5:"title";s:17:"Number of Volumes";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:43;a:4:{s:5:"title";s:7:"Section";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:28;a:4:{s:5:"title";s:5:"Issue";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:16;a:4:{s:5:"title";s:7:"Edition";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:18;a:4:{s:5:"title";s:6:"Number";s:4:"hint";s:0:"";s:6:"weight";s:2:"16";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:19;a:4:{s:5:"title";s:10:"Pagination";s:4:"hint";s:0:"";s:6:"weight";s:2:"17";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:20;a:4:{s:5:"title";s:14:"Date Published";s:4:"hint";s:9:"(mm/yyyy)";s:6:"weight";s:2:"18";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:13;a:4:{s:5:"title";s:9:"Publisher";s:4:"hint";s:0:"";s:6:"weight";s:2:"19";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:14;a:4:{s:5:"title";s:15:"Place Published";s:4:"hint";s:0:"";s:6:"weight";s:2:"20";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:25;a:4:{s:5:"title";s:12:"Type of Work";s:4:"hint";s:14:"Masters Thesis";s:6:"weight";s:2:"22";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:21;a:4:{s:5:"title";s:20:"Publication Language";s:4:"hint";s:0:"";s:6:"weight";s:2:"23";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:12;a:4:{s:5:"title";s:25:"Other Author Affiliations";s:4:"hint";s:0:"";s:6:"weight";s:2:"24";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:46;a:4:{s:5:"title";s:11:"ISSN Number";s:4:"hint";s:0:"";s:6:"weight";s:3:"150";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:9;a:4:{s:5:"title";s:11:"ISBN Number";s:4:"hint";s:0:"";s:6:"weight";s:3:"150";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:8;a:4:{s:5:"title";s:16:"Accession Number";s:4:"hint";s:0:"";s:6:"weight";s:3:"151";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:10;a:4:{s:5:"title";s:11:"Call Number";s:4:"hint";s:0:"";s:6:"weight";s:3:"152";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:11;a:4:{s:5:"title";s:13:"Other Numbers";s:4:"hint";s:0:"";s:6:"weight";s:3:"153";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:24;a:4:{s:5:"title";s:8:"Keywords";s:4:"hint";s:0:"";s:6:"weight";s:3:"154";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:12:"autocomplete";s:12:"autocomplete";s:8:"required";i:0;}}i:22;a:4:{s:5:"title";s:8:"Abstract";s:4:"hint";s:0:"";s:6:"weight";s:1:"1";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:23;a:4:{s:5:"title";s:15:"French Abstract";s:4:"hint";s:0:"";s:6:"weight";s:3:"156";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:27;a:4:{s:5:"title";s:5:"Notes";s:4:"hint";s:0:"";s:6:"weight";s:3:"157";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:26;a:4:{s:5:"title";s:3:"URL";s:4:"hint";s:0:"";s:6:"weight";s:3:"158";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:47;a:4:{s:5:"title";s:3:"DOI";s:4:"hint";s:0:"";s:6:"weight";s:3:"159";s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:29;a:4:{s:5:"title";s:13:"Reseach Notes";s:4:"hint";s:0:"";s:6:"weight";s:3:"160";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:30;a:4:{s:5:"title";s:8:"Custom 1";s:4:"hint";s:0:"";s:6:"weight";s:3:"161";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:31;a:4:{s:5:"title";s:8:"Custom 2";s:4:"hint";s:0:"";s:6:"weight";s:3:"162";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:32;a:4:{s:5:"title";s:8:"Custom 3";s:4:"hint";s:0:"";s:6:"weight";s:3:"163";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:33;a:4:{s:5:"title";s:8:"Custom 4";s:4:"hint";s:0:"";s:6:"weight";s:3:"164";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:34;a:4:{s:5:"title";s:8:"Custom 5";s:4:"hint";s:0:"";s:6:"weight";s:3:"165";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:35;a:4:{s:5:"title";s:8:"Custom 6";s:4:"hint";s:0:"";s:6:"weight";s:3:"167";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:36;a:4:{s:5:"title";s:8:"Custom 7";s:4:"hint";s:0:"";s:6:"weight";s:3:"168";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:38;a:4:{s:5:"title";s:11:"Short Title";s:4:"hint";s:0:"";s:6:"weight";s:3:"169";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:39;a:4:{s:5:"title";s:15:"Alternate Title";s:4:"hint";s:0:"";s:6:"weight";s:3:"170";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:40;a:4:{s:5:"title";s:16:"Translated Title";s:4:"hint";s:0:"";s:6:"weight";s:3:"170";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:41;a:4:{s:5:"title";s:20:"Original Publication";s:4:"hint";s:0:"";s:6:"weight";s:3:"171";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:42;a:4:{s:5:"title";s:15:"Reprint Edition";s:4:"hint";s:0:"";s:6:"weight";s:3:"172";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:44;a:4:{s:5:"title";s:12:"Citation Key";s:4:"hint";s:0:"";s:6:"weight";s:3:"175";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:45;a:4:{s:5:"title";s:10:"COinS Data";s:4:"hint";s:36:"This will be automatically generated";s:6:"weight";s:3:"176";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:49;a:4:{s:5:"title";s:20:"Remote Database Name";s:4:"hint";s:0:"";s:6:"weight";s:3:"176";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:50;a:4:{s:5:"title";s:24:"Remote Database Provider";s:4:"hint";s:0:"";s:6:"weight";s:3:"177";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:48;a:4:{s:5:"title";s:14:"Author Address";s:4:"hint";s:0:"";s:6:"weight";s:3:"178";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:51;a:4:{s:5:"title";s:5:"Label";s:4:"hint";s:0:"";s:6:"weight";s:3:"178";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}i:52;a:4:{s:5:"title";s:11:"Access Date";s:4:"hint";s:0:"";s:6:"weight";s:3:"179";s:10:"checkboxes";a:3:{s:6:"common";i:0;s:8:"required";i:0;s:12:"autocomplete";i:0;}}}s:2:"op";s:4:"Save";s:6:"submit";s:4:"Save";s:13:"form_build_id";s:37:"form-8e8b10346a884999bb99b9b1f34fd2a4";s:10:"form_token";s:32:"4d6475b789132c3b4092d8cf0149824e";s:7:"form_id";s:28:"biblio_admin_types_edit_form";}s:14:"clicked_button";a:18:{s:5:"#type";s:6:"submit";s:6:"#value";s:4:"Save";s:5:"#post";a:5:{s:15:"configured_flds";a:52:{i:15;a:4:{s:5:"title";s:19:"Year of Publication";s:4:"hint";s:33:"Enter YYYY, Submitted or In Press";s:10:"checkboxes";a:2:{s:6:"common";s:6:"common";s:8:"required";s:8:"required";}s:6:"weight";s:3:"-45";}i:1;a:5:{s:5:"title";s:7:"Authors";s:4:"hint";s:0:"";s:9:"auth_type";a:18:{i:0;s:1:"1";i:1;s:1:"2";i:2;s:1:"3";i:3;s:1:"4";i:4;s:1:"5";i:5;s:2:"10";i:6;s:2:"11";i:7;s:2:"12";i:8;s:2:"13";i:9;s:2:"14";i:10;s:2:"15";i:11;s:2:"16";i:12;s:2:"17";i:13;s:2:"18";i:14;s:2:"19";i:15;s:2:"20";i:16;s:2:"21";i:17;s:2:"22";}s:10:"checkboxes";a:3:{s:6:"common";s:6:"common";s:8:"required";s:8:"required";s:12:"autocomplete";s:12:"autocomplete";}s:6:"weight";s:1:"2";}i:2;a:4:{s:5:"title";s:17:"Secondary Authors";s:4:"hint";s:0:"";s:9:"auth_type";a:1:{i:0;s:1:"2";}s:6:"weight";s:1:"2";}i:3;a:4:{s:5:"title";s:16:"Tertiary Authors";s:4:"hint";s:0:"";s:9:"auth_type";a:1:{i:0;s:1:"3";}s:6:"weight";s:1:"3";}i:4;a:4:{s:5:"title";s:18:"Subsidiary Authors";s:4:"hint";s:0:"";s:9:"auth_type";a:1:{i:0;s:1:"4";}s:6:"weight";s:1:"4";}i:5;a:4:{s:5:"title";s:17:"Corporate Authors";s:4:"hint";s:0:"";s:9:"auth_type";a:1:{i:0;s:1:"5";}s:6:"weight";s:1:"5";}i:6;a:3:{s:5:"title";s:15:"Secondary Title";s:4:"hint";s:0:"";s:6:"weight";s:2:"12";}i:7;a:3:{s:5:"title";s:14:"Tertiary Title";s:4:"hint";s:0:"";s:6:"weight";s:2:"13";}i:17;a:3:{s:5:"title";s:6:"Volume";s:4:"hint";s:0:"";s:6:"weight";s:2:"14";}i:37;a:3:{s:5:"title";s:17:"Number of Volumes";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";}i:43;a:3:{s:5:"title";s:7:"Section";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";}i:28;a:3:{s:5:"title";s:5:"Issue";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";}i:16;a:3:{s:5:"title";s:7:"Edition";s:4:"hint";s:0:"";s:6:"weight";s:2:"15";}i:18;a:3:{s:5:"title";s:6:"Number";s:4:"hint";s:0:"";s:6:"weight";s:2:"16";}i:19;a:3:{s:5:"title";s:10:"Pagination";s:4:"hint";s:0:"";s:6:"weight";s:2:"17";}i:20;a:3:{s:5:"title";s:14:"Date Published";s:4:"hint";s:9:"(mm/yyyy)";s:6:"weight";s:2:"18";}i:13;a:3:{s:5:"title";s:9:"Publisher";s:4:"hint";s:0:"";s:6:"weight";s:2:"19";}i:14;a:3:{s:5:"title";s:15:"Place Published";s:4:"hint";s:0:"";s:6:"weight";s:2:"20";}i:25;a:3:{s:5:"title";s:12:"Type of Work";s:4:"hint";s:14:"Masters Thesis";s:6:"weight";s:2:"22";}i:21;a:3:{s:5:"title";s:20:"Publication Language";s:4:"hint";s:0:"";s:6:"weight";s:2:"23";}i:12;a:3:{s:5:"title";s:25:"Other Author Affiliations";s:4:"hint";s:0:"";s:6:"weight";s:2:"24";}i:46;a:3:{s:5:"title";s:11:"ISSN Number";s:4:"hint";s:0:"";s:6:"weight";s:3:"150";}i:9;a:4:{s:5:"title";s:11:"ISBN Number";s:4:"hint";s:0:"";s:10:"checkboxes";a:1:{s:6:"common";s:6:"common";}s:6:"weight";s:3:"150";}i:8;a:4:{s:5:"title";s:16:"Accession Number";s:4:"hint";s:0:"";s:10:"checkboxes";a:1:{s:6:"common";s:6:"common";}s:6:"weight";s:3:"151";}i:10;a:4:{s:5:"title";s:11:"Call Number";s:4:"hint";s:0:"";s:10:"checkboxes";a:1:{s:6:"common";s:6:"common";}s:6:"weight";s:3:"152";}i:11;a:4:{s:5:"title";s:13:"Other Numbers";s:4:"hint";s:0:"";s:10:"checkboxes";a:1:{s:6:"common";s:6:"common";}s:6:"weight";s:3:"153";}i:24;a:4:{s:5:"title";s:8:"Keywords";s:4:"hint";s:0:"";s:10:"checkboxes";a:2:{s:6:"common";s:6:"common";s:12:"autocomplete";s:12:"autocomplete";}s:6:"weight";s:3:"154";}i:22;a:4:{s:5:"title";s:8:"Abstract";s:4:"hint";s:0:"";s:10:"checkboxes";a:1:{s:6:"common";s:6:"common";}s:6:"weight";s:1:"1";}i:23;a:3:{s:5:"title";s:15:"French Abstract";s:4:"hint";s:0:"";s:6:"weight";s:3:"156";}i:27;a:3:{s:5:"title";s:5:"Notes";s:4:"hint";s:0:"";s:6:"weight";s:3:"157";}i:26;a:4:{s:5:"title";s:3:"URL";s:4:"hint";s:0:"";s:10:"checkboxes";a:1:{s:6:"common";s:6:"common";}s:6:"weight";s:3:"158";}i:47;a:4:{s:5:"title";s:3:"DOI";s:4:"hint";s:0:"";s:10:"checkboxes";a:1:{s:6:"common";s:6:"common";}s:6:"weight";s:3:"159";}i:29;a:3:{s:5:"title";s:13:"Reseach Notes";s:4:"hint";s:0:"";s:6:"weight";s:3:"160";}i:30;a:3:{s:5:"title";s:8:"Custom 1";s:4:"hint";s:0:"";s:6:"weight";s:3:"161";}i:31;a:3:{s:5:"title";s:8:"Custom 2";s:4:"hint";s:0:"";s:6:"weight";s:3:"162";}i:32;a:3:{s:5:"title";s:8:"Custom 3";s:4:"hint";s:0:"";s:6:"weight";s:3:"163";}i:33;a:3:{s:5:"title";s:8:"Custom 4";s:4:"hint";s:0:"";s:6:"weight";s:3:"164";}i:34;a:3:{s:5:"title";s:8:"Custom 5";s:4:"hint";s:0:"";s:6:"weight";s:3:"165";}i:35;a:3:{s:5:"title";s:8:"Custom 6";s:4:"hint";s:0:"";s:6:"weight";s:3:"167";}i:36;a:3:{s:5:"title";s:8:"Custom 7";s:4:"hint";s:0:"";s:6:"weight";s:3:"168";}i:38;a:3:{s:5:"title";s:11:"Short Title";s:4:"hint";s:0:"";s:6:"weight";s:3:"169";}i:39;a:3:{s:5:"title";s:15:"Alternate Title";s:4:"hint";s:0:"";s:6:"weight";s:3:"170";}i:40;a:3:{s:5:"title";s:16:"Translated Title";s:4:"hint";s:0:"";s:6:"weight";s:3:"170";}i:41;a:3:{s:5:"title";s:20:"Original Publication";s:4:"hint";s:0:"";s:6:"weight";s:3:"171";}i:42;a:3:{s:5:"title";s:15:"Reprint Edition";s:4:"hint";s:0:"";s:6:"weight";s:3:"172";}i:44;a:3:{s:5:"title";s:12:"Citation Key";s:4:"hint";s:0:"";s:6:"weight";s:3:"175";}i:45;a:3:{s:5:"title";s:10:"COinS Data";s:4:"hint";s:36:"This will be automatically generated";s:6:"weight";s:3:"176";}i:49;a:3:{s:5:"title";s:20:"Remote Database Name";s:4:"hint";s:0:"";s:6:"weight";s:3:"176";}i:50;a:3:{s:5:"title";s:24:"Remote Database Provider";s:4:"hint";s:0:"";s:6:"weight";s:3:"177";}i:48;a:3:{s:5:"title";s:14:"Author Address";s:4:"hint";s:0:"";s:6:"weight";s:3:"178";}i:51;a:3:{s:5:"title";s:5:"Label";s:4:"hint";s:0:"";s:6:"weight";s:3:"178";}i:52;a:3:{s:5:"title";s:11:"Access Date";s:4:"hint";s:0:"";s:6:"weight";s:3:"179";}}s:2:"op";s:4:"Save";s:13:"form_build_id";s:37:"form-5192a1785bde6ff797761ec41b122f5e";s:10:"form_token";s:32:"4d6475b789132c3b4092d8cf0149824e";s:7:"form_id";s:28:"biblio_admin_types_edit_form";}s:11:"#programmed";b:0;s:5:"#tree";b:0;s:8:"#parents";a:1:{i:0;s:6:"submit";}s:14:"#array_parents";a:1:{i:0;s:6:"submit";}s:7:"#weight";d:0.003000000000000000062450045135165055398829281330108642578125;s:10:"#processed";b:0;s:12:"#description";N;s:11:"#attributes";a:0:{}s:9:"#required";b:0;s:6:"#input";b:1;s:5:"#name";s:2:"op";s:12:"#button_type";s:6:"submit";s:25:"#executes_submit_callback";b:1;s:8:"#process";a:1:{i:0;s:16:"form_expand_ahah";}s:3:"#id";s:11:"edit-submit";}}
COMMON;
   
   include_once(drupal_get_path('module','biblio')."/biblio.admin.inc");
   drupal_execute('biblio_admin_types_edit_form',unserialize(trim($s_common_string)));
   
   db_query("UPDATE `biblio_field_type` SET visible = 0 WHERE fid IN(2,3,4,5) AND visible = 1"); //Hide all the other authers
   db_query("UPDATE `biblio_field_type` SET weight = -1 WHERE fid = 22");  //Move Abstract
   db_query("UPDATE `biblio_field_type` SET required = 0 WHERE fid = 15"); //No pub date req.
}

function   _openscholar_dev_wysiwyg_config(){
  $settings = array (
    'default' => 1,
    'user_choose' => 0,
    'show_toggle' => 1,
    'theme' => 'advanced',
    'language' => 'en',
    'buttons' => array(
      'default' => array (
         'bold' => 1,
         'italic' => 1,
         'strikethrough' => 1,
         'bullist' => 1,
         'numlist' => 1,
         'link' => 1,
         'unlink' => 1,
         'image' => 1,
         'code' => 1,
         'cut' => 1,
         'copy' => 1,
         'paste' => 1,
         'charmap' => 1,
       ),
            
       'font' => array('formatselect' => 1),
       'fullscreen' => array('fullscreen' => 1),
       'paste' => array('pastetext' => 1),
       'table' => array('tablecontrols' => 1),
       'safari' => array('safari' => 1),
       'drupal' => array ('break' => 1),
    ),

    'toolbar_loc' => 'top',
    'toolbar_align' => 'left',
    'path_loc' => 'bottom',
    'resizing' => 1,
    'verify_html' => 1,
    'preformatted' => 0,
    'convert_fonts_to_spans' => 1,
    'remove_linebreaks' => 1,
    'apply_source_formatting' => 0,
    'paste_auto_cleanup_on_paste' => 1,
    'block_formats' => 'p,address,pre,h2,h3,h4,h5,h6',
    'css_setting' => 'theme',
    'css_path' => '',
    'css_classes' => '',

);

$settings = serialize($settings);

  $query = "SELECT format FROM {filter_formats} WHERE name='%s'";
  $filter_name = db_result(db_query($query,'Filtered HTML'));
  $query = "INSERT INTO {wysiwyg} (format, editor, settings) VALUES ('%d', '%s', '%s')";
  db_query($query, $filter_name, 'tinymce', $settings);
}

/**
 *  Creates roles and permissions
 */
function _openscholar_dev_create_roles(){
  install_add_role('scholar admin');
  install_add_role('scholar user');
}
