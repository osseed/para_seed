<?php

/**
 * @file
 * Enables modules and site configuration for a Para Seed site installation.
 */

use Drupal\Core\Form\FormStateInterface;
use Drupal\file\Entity\File;
use Symfony\Component\Yaml\Yaml;
use Drupal\node\Entity\Node;
use Drupal\para_seed\Form\AssemblerForm;
use Drupal\para_seed\Config\ConfigBit;

/**
 * Implements hook_form_FORM_ID_alter() for install_configure_form().
 *
 * Allows the profile to alter the site configuration form.
 */
function para_seed_form_install_configure_form_alter(&$form, FormStateInterface $form_state) {
  // Add a placeholder as example that one can choose an arbitrary site name.
  $form['site_information']['site_name']['#attributes']['placeholder'] = t('Site Name');

  // Default site email noreply@paraseed.com .
  $form['site_information']['site_mail']['#default_value'] = 'noreply@paraseed.com';
  $form['site_information']['site_mail']['#attributes']['style'] = 'width: 25em;';

  // Default user 1 username should be 'admin'.
  $form['admin_account']['account']['name']['#default_value'] = 'admin';
  $form['admin_account']['account']['name']['#attributes']['disabled'] = TRUE;
  $form['admin_account']['account']['mail']['#default_value'] = 'admin@paraseed.com';
}

/**
 * Implements hook_install_tasks().
 */
function para_seed_install_tasks(&$install_state) {

  return [
    'para_seed_extra_components' => [
      'display_name' => t('Extra components'),
      'display' => TRUE,
      'type' => 'form',
      'function' => AssemblerForm::class,
    ],
    'para_seed_assemble_extra_components' => [
      'display_name' => t('Assemble extra components'),
      'display' => TRUE,
      'type' => 'batch',
    ],
  ];
}

/**
 * Batch job to assemble Varbase extra components.
 *
 * @param array $install_state
 *   The current install state.
 *
 * @return array
 *   The batch job definition.
 */
function para_seed_assemble_extra_components(array &$install_state) {

  $batch = [];

  // Install selected extra features.
  $selected_extra_features = [];
  $selected_extra_features_configs = [];

  if (isset($install_state['para_seed']['extra_features_values'])) {
    $selected_extra_features = $install_state['para_seed']['extra_features_values'];
  }

  if (isset($install_state['para_seed']['extra_features_configs'])) {
    $selected_extra_features_configs = $install_state['para_seed']['extra_features_configs'];
  }

  // Get the list of extra features config bits.
  $extraFeatures = ConfigBit::getList('configbit/extra.components.para_seed.bit.yml', 'show_extra_components', TRUE, 'dependencies', 'profile', 'para_seed');

  // If we do have selected extra features.
  if (count($selected_extra_features) && count($extraFeatures)) {
    // Have batch processes for each selected extra features.
    foreach ($selected_extra_features as $extra_feature_key => $extra_feature_checked) {
      if ($extra_feature_checked) {

        // If the extra feature was a module and not enabled, then enable it.
        if (!\Drupal::moduleHandler()->moduleExists($extra_feature_key)) {
          // Add the checked extra feature to the batch process to be enabled.
          $batch['operations'][] = ['para_seed_assemble_extra_component_then_install', (array) $extra_feature_key];
        }
      }
    }
  }

  return $batch;
}

/**
 * Batch function to assemble and install needed extra components.
 *
 * @param string|array $extra_component
 *   Name of the extra component.
 */
function para_seed_assemble_extra_component_then_install($extra_component) {
  \Drupal::service('module_installer')->install((array) $extra_component, TRUE);
}

/**
 * Implements hook_theme().
 */
function para_seed_theme($existing, $type, $theme, $path) {
  $templates = $path . '/templates';

  $return['swiftmailer'] = [
    'template' => 'para_seed',
    'path' => $templates,
    'variables' => [
      'message' => [],
    ],
    'mail theme' => TRUE,
  ];
  return $return;
}

/**
 * Prepares variables for para_seed.html.twig templates.
 *
 * Implements hook_preprocess_HOOK() for field templates.
 */
function para_seed_preprocess_swiftmailer(&$variables) {
  $language = \Drupal::languageManager()->getCurrentLanguage();
  $theme_id = \Drupal::config('system.theme')->get('default');
  $site_config = \Drupal::config('system.site');

  $request = \Drupal::request();
  $host = $request->getSchemeAndHttpHost();

  $variables['dir'] = $language->getDirection();
  // Default we use the logo image.
  if (theme_get_setting('email_logo_default', $theme_id)) {
    $variables['logo'] = $host . theme_get_setting('logo.url', $theme_id);
  }
  else {
    $fid = theme_get_setting('email_logo_upload', $theme_id);
    if ($fid && is_array($fid) && count($fid)) {
      $file = File::load($fid[0]);
      if ($file) {
        $url = $file->createFileUrl();
        $variables['logo'] = $url;
      }
    }
    elseif (theme_get_setting('email_logo_path', $theme_id)) {
      $uri = theme_get_setting('email_logo_path', $theme_id);
      $scheme = \Drupal::service('file_system')->uriScheme($uri);

      if ($scheme) {
        $variables['logo'] = file_create_url($uri);
      }
      else {
        $variables['logo'] = $host . file_create_url($uri);
      }
    }
    else {
      $variables['logo'] = $host . theme_get_setting('logo.url', $theme_id);
    }
  }

  if ($site_config) {
    $variables['site_link'] = TRUE;
    $variables['site_name'] = $site_config->get('name');
    if ($site_config->get('slogan')) {
      $variables['site_slogan'] = $site_config->get('slogan');
    }
  }
  else {
    $variables['site_name'] = t('Osseed');
    $variables['site_slogan'] = '"' . t('The Osseed Drupal8 Installation Profile') . '"';
  }
}
