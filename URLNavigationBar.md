# URL Navigation Bar

## Overview

The URL navigation bar is the primary interface component for browsing the web in the Tracker Blocking Browser. It allows users to enter URLs, view the current page address, navigate through browsing history, and access privacy controls.

## Components

The navigation bar consists of several key components:

1. **Back/Forward Navigation Buttons**
   - Located on the left side of the navigation bar
   - Enable moving backward and forward through browsing history
   - Automatically enable/disable based on available navigation history

2. **URL Text Field**
   - Displays the current page URL
   - Allows users to enter new URLs or search terms
   - Supports "Go" action via the keyboard
   - Handles various URL formats and search queries

3. **Privacy Protection Button**
   - Toggles tracker blocking for the current website
   - Green shield icon when protection is enabled
   - Red slashed shield icon when protection is disabled

4. **Tracker Test Button**
   - Allows users to test the effectiveness of the tracker blocking
   - Opens a special test page that simulates various tracking techniques

## URL Navigation Behavior

### URL Input Handling

When a user enters text in the URL field and taps "Go" on the keyboard, the text is processed as follows:

1. **Direct URL with scheme**
   - If input contains a scheme (http://, https://), it's loaded directly
   - Example: `https://example.com` → loads that exact URL

2. **URL without scheme**
   - If input contains a domain-like pattern (contains "." but no spaces)
   - Example: `example.com` → automatically prefixed with `https://`

3. **Search query**
   - If input doesn't match URL patterns, it's treated as a search query
   - Text is encoded and sent to DuckDuckGo search
   - Example: `privacy browser` → searches DuckDuckGo for "privacy browser"

### Navigation Actions

- **Return/Go key**: Initiates navigation to the entered URL or search query
- **Back button**: Returns to the previous page in the browsing history
- **Forward button**: Advances to the next page if user has gone back
- **Double-tap on WebView**: Alternative gesture to go back in history

## Error Handling

The URL bar system handles several error cases:

- **Invalid URLs**: Shows an error view when a URL cannot be resolved
- **Network errors**: Displays appropriate error messages
- **Security issues**: Handles HTTPS errors appropriately

## User Interaction Flow

1. User enters a URL or search term in the URL field
2. User taps "Go" on the keyboard
3. The input is processed to determine if it's a URL or search query
4. The appropriate page is loaded in the WebView
5. The URL field updates to show the actual URL of the loaded page
6. Navigation buttons update based on the available browsing history

## Design Considerations

- The URL field uses rounded corners to match iOS design patterns
- Navigation buttons follow system appearance guidelines
- The privacy button uses color to clearly indicate protection status
- The layout is designed to be space-efficient on mobile devices

## Tracker Test Page

The tracker test page is a specialized feature that allows users to verify the effectiveness of the tracker blocking functionality.

### Features

- **Simulated Trackers**: The test page includes various types of simulated trackers commonly found on websites
- **Real-time Results**: Shows which trackers were successfully blocked and which were allowed
- **Protection Verification**: Allows users to toggle protection and see immediate differences
- **Educational Content**: Explains different tracking techniques and how they affect privacy

### How to Access

Users can access the test page in two ways:
1. Tap the yellow shield checkerboard button in the URL bar
2. Navigate directly to `https://tracker-test.local/`

### User Experience

When a user activates the test page:
1. A confirmation dialog appears to explain the purpose of the test
2. Upon confirmation, the test page loads with tracker protection enabled
3. The navigation title changes to indicate test mode
4. Results display showing which trackers were blocked
5. Users can toggle protection to see the difference in blocking effectiveness
