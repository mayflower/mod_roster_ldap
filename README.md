# Prosody shared roster from LDAP

**This is a incompatible fork of https://github.com/tdubrownik/mod_roster_ldap**

## Changes in this fork

 * Change code to work solely with GOsa object groups (**backwards-incompatible change**)
 * Remove `ldap_filter` configuration option
 * Add `ldap_group_base` and `ldap_group_filter` configuration option

## Original Description

This is a toy shared roster written for Hackerspace Warsaw - it pulls all users from a prescribed group and automatically adds them to a user's roster.

Very basic functionality, more updates hopefully coming soon.
