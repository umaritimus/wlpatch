# wlpatch

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with wlpatch](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with wlpatch](#beginning-with-wlpatch)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

wlpatch is a puppet module designed to assist deploying `WLS STACK PATCH BUNDLE`s

## Setup

### Setup Requirements

Ensure that prior to execution of wlpatch, you define the weblogic_patches hash in you dpk hiera following psft_patches format, e.g.

```yaml
---
weblogic_patches:
  34084007: "//share/patches/34084007 - WLS STACK PATCH BUNDLE 14.1.1.0.220418/p34084007_141100_Generic.zip"
```

### Beginning with wlpatch

To use wlpatch puppet module, add references to wlpatch into your dpk profile or call it ad-hoc using

```cmd
puppet.bat apply -e "include wlpatch"
```

## Limitations

Currently, wlpatch only works on windows.

## Development

Please submit a PR to contribute new functionality or a fix.
