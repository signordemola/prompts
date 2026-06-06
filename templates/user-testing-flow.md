Phase ONE:


You already know this project extremely well since you helped build it.

Create the complete content for a file called DOMAIN.md.

The purpose of this file is to give Gemini in Antigravity deep, rich contextual understanding of the project, including broader industry knowledge, so it can perform intelligent real-user testing without repeatedly scanning project files.

Make the DOMAIN.md comprehensive. Include:

- What the project is and its core philosophy
- The specific niche and target businesses
- Who the main users are (studio owners/admins and clients) and their real-world challenges
- Full scope of client-side user flows
- Full scope of admin/owner-side user flows
- Industry standards and best practices for booking + operations systems in beauty/wellness, photography, coaching, and event service businesses (include common expectations around deposits, reminders, no-shows, payments, file handling, mobile usage, etc.)
- Key testing priorities and what "good" connected flows should feel like

Output ONLY the raw content of the DOMAIN.md file. No explanations, no extra text.



-----------------------------------------------------------------------


Phase TWO:


Read and deeply internalize the file DOMAIN.md in the project root.

After internalizing it, use your knowledge and browser capabilities to research current industry standards and best practices for booking & operations systems in the service business niche (beauty/wellness, photography, coaching, consultants, event providers).

Research key areas:
- User expectations and common pain points
- Standard features for deposits, payments, reminders, no-shows, client files
- Mobile-first usage patterns for owners and clients
- What makes booking flows feel professional and "connected"

Then respond with:
1. Confirmation that you have fully internalized DOMAIN.md
2. Summary of key industry standards you researched
3. List of high-value real-user test scenarios

Stay in Planning Mode. Do not execute any test until I explicitly approve.


-----------------------------------------------------------------------


Phase THREE:




You now have full knowledge of the project from DOMAIN.md.

From now on, always reference and follow DOMAIN.md when doing any testing.

Confirm: "I have internalized DOMAIN.md and will use it as the core project context for all testing."



-----------------------------------------------------------------------


Phase FOUR:





################################################################

SCENARIO 1: New Client Booking with Deposit
Test the complete new client booking flow: browse services → select date and time → fill client details → pay deposit → receive confirmation and reminder scheduling.

################################################################

SCENARIO 2: Returning Client Quick Rebooking
Test returning client experience: login → view booking history → quick rebook same or similar service → complete payment.

################################################################

SCENARIO 3: Admin Manual Booking Creation
Test owner/admin creating a new booking manually through the dashboard for a client.

################################################################

SCENARIO 4: Payment Failure and Recovery
Test failed payment during booking and the full recovery/retry flow.

################################################################

SCENARIO 5: Client Cancellation
Test client cancelling a booking (both within and outside cancellation window).

################################################################

SCENARIO 6: No-Show Handling
Test complete no-show scenario: appointment time passes → system marks as no-show → automated follow-up and possible fee application.

################################################################

SCENARIO 7: Booking Rescheduling
Test client rescheduling an existing booking and verify availability is correctly updated.

################################################################

SCENARIO 8: Client File Upload Before Appointment
Test client uploading required files/documents before their appointment.

################################################################

SCENARIO 9: Owner File Delivery After Service
Test owner uploading and delivering files (photos, documents, etc.) to the client after service.

################################################################

SCENARIO 10: Admin Dashboard Overview
Test the main admin/owner dashboard: upcoming bookings, revenue metrics, pending actions, and quick navigation.

################################################################

SCENARIO 11: Incomplete / Abandoned Booking
Test user starting a booking but abandoning it at the deposit/payment stage.

################################################################

SCENARIO 12: Multi-Session Package Booking
Test booking a package or series of multiple sessions.

################################################################

SCENARIO 13: Full Reminder Sequence
Test the complete automated reminder flow (immediate confirmation → 24h reminder → 2h reminder).

################################################################

SCENARIO 14: Login and Role-Based Access
Test login flows and verify correct permissions for owner/admin vs client views.

################################################################

SCENARIO 15: Slot No Longer Available
Test booking attempt when the selected time slot has already been taken by another user.

################################################################

SCENARIO 16: Waitlist / Request Booking
Test user joining a waitlist for a fully booked service and receiving notification when a slot opens.

################################################################

SCENARIO 17: Group or Event Booking
Test booking for multiple people or a group/event session.

################################################################

SCENARIO 18: Last-Minute Booking
Test booking a session with very short notice (same day or few hours away).

################################################################

SCENARIO 19: Payment Balance Due After Deposit
Test paying remaining balance after initial deposit (post-booking or post-service).

################################################################

SCENARIO 20: Full End-to-End Booking Journey
Test the complete journey from client booking with deposit → owner approval → service day → file delivery → follow-up.
