SL-XOBJ
=======

An LSL framework with methods, events, macros and prim DB

XOBJ is a framework for SL Firestorm in an attempt to make a more modular approach, allowing you to do more with less code and have, and making your code more portable!

xobj supports the following features:
* Events
* Methods with optional callbacks
* Prim DB
* Macros

**Learn how to use it on [the XOBJ Github-Wiki](https://github.com/JasXSL/SL-XOBJ/wiki)!**

#Update 0.3.0
DB2 has been replaced with DB3 and I have adopted a new philosophy on shared vars. DB3 will consume less memory and automatically preserve tables between script resets. But it runs a little slower and requires you to set up the tables in #ROOT.


#Install
1. Create a folder for SL libraries on your drive (example C:\LSL)
2. Download XOBJ as zip and extract the contents of the master folder to your SL libraries directory (C:\LSL). The important part is that you now have C:\LSL\xobj_core & C:\LSL\xobj_toonie folders. If you are familiar with git, you can also git clone and add these folders as symlinks in your libraries directory.
3. Open a script window in your Firestorm viewer. Click the cogs icon at the top and check Enable LSL preprocessor. Then check **Script optimizer** and **#includes from local disk**. The other checkboxes are optional.
4. Click the ... button and navigate to your libraries directory (C:\LSL)
5. Close and re-open your script window. Then hit OK.
6. To test if it works create a new default LSL script (hello avatar), and above default add #include "xobj_core/_ROOT.lsl" Then compile. If you get no errors, it worked!
