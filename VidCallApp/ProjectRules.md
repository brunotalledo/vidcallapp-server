# VidCallApp Project Rules

## Code Change Guidelines

1. **Only make changes that are explicitly requested by the user**
   - Do not add features or make improvements unless specifically asked
   - Do not refactor code unless requested
   - Do not change styling or UI elements unless directed

2. **When making changes:**
   - Make only the specific changes requested
   - Keep the existing code structure intact
   - Preserve all other functionality
   - Do not add additional features or improvements

3. **Communication:**
   - Ask for clarification if a request is unclear
   - Explain what changes will be made before implementing them
   - Wait for confirmation before proceeding with significant changes

4. **Code Quality:**
   - Maintain existing code style and formatting
   - Follow the established patterns in the codebase
   - Ensure changes are compatible with the rest of the application

5. **Testing:**
   - Ensure changes don't break existing functionality
   - Verify that requested changes work as expected

## Example of Good Practice

If the user asks: "Add a logout button to the profile page"

✅ Good response:
- "I'll add a logout button to the ProfileView that will navigate back to the login page when pressed."
- Make only the specific changes needed for the logout functionality
- Keep all other code unchanged

❌ Bad response:
- Adding additional features like confirmation dialogs
- Changing the button styling
- Refactoring other parts of the code
- Adding animations or transitions

## Example of Bad Practice

If the user asks: "Fix the text color in the login form"

❌ Bad response:
- Changing the background color
- Adjusting the font size
- Adding new validation rules
- Modifying other UI elements

✅ Good response:
- Only changing the text color as requested
- Keeping all other styling and functionality intact

## Summary

The key principle is to make only the specific changes requested by the user and nothing more. This ensures that the development process remains focused and controlled according to the user's requirements. 