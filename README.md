# AddressBookSync
This is an assignment from the company in Singapore, they require it as a part of their interview process.

Details
	An application which can determine changes in address book (which contact(s) and which fields(s) has been changed since the application was last opened). Please ensure that the Task works for both iOS 8.X and iOS 9.x, written in xCode 7.0
 
	Screen should contain 1 text view (text - “Syncing is in progress Please wait”/ “Sync is done”), 1 button (text - “Check address book changes”)
 
	Behavior:
 
1. After installation, the app should copy contacts from the address book and store them locally inside of the local application database (names and numbers only)
 
2. During copy/sync there should be some progress indicator shown (something simple, just text “Syncing is in progress please wait”),  and the “Check address book changes” button should be invisible 
 
3. After saving/copying into the local db is done, the app should show the status - “Sync is done”,  the “Check address book changes” button should become visible
 
4. If user presses the “Check address book changes” button there should be a comparison made of the local copy of the address book and the real address book from device
 
5. The Comparison output is dialog will show either “No changes” or changed contacts list “<Contact name> <Number, Number>”.
	
	![alt tag](https://github.com/BenjaminTamTran/AddressBookSync/blob/master/Assets/Screen%20shoot%201.png)
	![alt tag](https://github.com/BenjaminTamTran/AddressBookSync/blob/master/Assets/Screen%20shoot%202.png)
	![alt tag](https://github.com/BenjaminTamTran/AddressBookSync/blob/master/Assets/Screen%20shoot%203.png)