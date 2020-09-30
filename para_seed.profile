<?php

/**
 * @file
 * Enables modules and site configuration for a Para Seed site installation.
 */

use Drupal\Core\Form\FormStateInterface;
use Drupal\file\Entity\File;

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

/**
 * Implements hook_form_FORM_ID_alter() for install_configure_form().
 *
 * Allows the profile to alter the site configuration form.
 */
function para_seed_form_install_configure_form_alter(&$form, FormStateInterface $form_state) {
  $form['#submit'][] = 'para_seed_form_install_configure_submit';
}

/**
 * Submission handler to sync the contact.form.feedback recipient.
 */
function para_seed_form_install_configure_submit($form, FormStateInterface $form_state) {

}
