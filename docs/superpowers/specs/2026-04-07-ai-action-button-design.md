# AI Message Action Button Feature Design

**Date:** 2026-04-07  
**Status:** Approved

## Overview
Port the existing frontend action button feature to Flutter. When an AI message contains metadata with an `actionType`, display a styled button that navigates to the relevant page (Calendar or Stats) with contextual parameters pre-selected.

## Architecture

### Components to create:
1. **ActionButton widget** (`action_button.dart`)
   - Receives ChatMessage (with metadata)
   - Determines action type and target route
   - Renders button with appropriate icon and label

2. **ChatBubble widget enhancement** (`chat_bubble.dart`)
   - Accept full ChatMessage object (currently only gets message content)
   - Render ActionButton below message when metadata exists
   - Support rendering ReportCard and ReportChart sections

3. **Report rendering widgets**
   - `ReportCard` — for card/alert/suggestion sections
   - `ReportChart` — for pie/bar/line chart sections

4. **Route parameter updates**
   - Calendar: accept `?date=YYYY-MM-DD` query parameter
   - Stats: accept `?month=YYYY-MM` query parameter

## Navigation Logic

- **Calendar actions** (create/update/delete): Navigate to `/calendar?date=YYYY-MM-DD`
- **Stats actions** (read/report): Navigate to `/stats?month=YYYY-MM`
- Extract date/month from `metadata.action.date` or `metadata.report.params.month`
- Fallback to current date/month if not provided
- Use GoRouter with query parameters (consistent with frontend)

## Data Flow

1. AI Chat Page receives full ChatMessage with metadata from API
2. Pass ChatMessage to ChatBubble widget
3. ChatBubble renders message content, report sections, and ActionButton
4. ActionButton extracts metadata, determines route, and navigates on tap
5. Target page (Calendar/Stats) reads query parameters and pre-selects date/month

## Files to modify/create:

### Create:
- `flutter_app/lib/features/ai_chat/widgets/action_button.dart` — Navigation button component
- `flutter_app/lib/features/ai_chat/widgets/report_card.dart` — Report card/alert/suggestion rendering
- `flutter_app/lib/features/ai_chat/widgets/report_chart.dart` — Chart rendering (pie/bar/line)

### Modify:
- `flutter_app/lib/features/ai_chat/widgets/chat_bubble.dart` — Accept ChatMessage, render reports + button
- `flutter_app/lib/features/ai_chat/ai_chat_page.dart` — Pass full ChatMessage object
- `flutter_app/lib/features/calendar/calendar_page.dart` — Read and apply `date` query parameter
- `flutter_app/lib/features/stats/stats_page.dart` — Read and apply `month` query parameter

## Implementation Approach

1. Create ActionButton widget with navigation logic
2. Create report card and chart widgets (start simple)
3. Update ChatBubble to accept ChatMessage and render all sections
4. Update AIChatPage to pass full ChatMessage objects
5. Update Calendar and Stats pages to read and pre-select from query parameters
