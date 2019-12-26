<?php

/**
 * @file
 * Enables modules and site configuration for a Para Seed site installation.
 */

use Drupal\Core\Form\FormStateInterface;

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