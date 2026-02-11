# Documentation Templates

This document provides templates for common documentation types
in the Maildroid project.

## README Template

Use this template for the project README:

```markdown
# Maildroid

Brief one-paragraph description of the project.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Development](#development)

## Features

Maildroid provides the following capabilities:

- First feature as a complete sentence.
- Second feature as a complete sentence.

## Prerequisites

Before installing, ensure you have:

- [Xcode](https://developer.apple.com/xcode/) 15.0 or higher.
- A Google Cloud project with Gmail API enabled.

## Installation

Clone the repository:

` ` `bash
git clone https://github.com/user/maildroid.git
cd maildroid
` ` `

Build the project:

` ` `bash
swift build
` ` `

## Configuration

Copy the configuration template:

` ` `bash
cp Maildroid/Sources/Config.template.swift \
   Maildroid/Sources/Config.swift
` ` `

Edit `Config.swift` with your Google OAuth credentials.

## Usage

Run the application from Xcode or the command line.

## Development

Run tests:

` ` `bash
swift test
` ` `
```

## Feature Documentation Template

Use this template for documenting features:

```markdown
# Feature Name

Brief description of the feature and its purpose.

## Overview

The feature provides the following capabilities:

- Capability one as a complete sentence.
- Capability two as a complete sentence.

## How It Works

Explain the feature's operation:

1. First step in the process.
2. Second step in the process.
3. Third step in the process.

## Configuration

Describe how to configure the feature.

## Usage Examples

### Basic Usage

In the following example, the user performs a basic operation:

` ` `swift
// Example code here
` ` `
```
