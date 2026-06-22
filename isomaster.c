/******************************* LICENCE **************************************
* Any code in this file may be redistributed or modified under the terms of
* the GNU General Public Licence as published by the Free Software 
* Foundation; version 2 of the licence.
****************************** END LICENCE ***********************************/

/******************************************************************************
* Author:
* Andrew Smith, http://littlesvr.ca/misc/contactandrew.php
*
* Contributors:
* David Johnson
* - open an iso file based on command-line parameter
* - print a help message when --help parameter given
******************************************************************************/

#include <gtk/gtk.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <signal.h>

#include "isomaster.h"

GtkWidget* GBLmainWindow;
/* to be able to resize the two file browsers */
GtkWidget* GBLbrowserPaned;
/* GTK4 application instance */
GtkApplication* GBLapp;

extern AppSettings GBLappSettings;

/* ISO file to open (set from command line before app starts) */
static char* GBLisoFileToOpen = NULL;

static void activate(GtkApplication* app, gpointer user_data)
{
    GdkPixbuf* appIcon;
    GtkWidget* mainVBox;
    GtkWidget* mainFrame; /* to put a border around the window contents */
    GtkWidget* topPanedBox; /* to pack the top part of GBLbrowserPaned */
    GtkWidget* bottomPanedBox; /* to pack the bottom part of GBLbrowserPaned */
    GtkWidget* statusBar;
    
    loadAppIcon(&appIcon);
    
    /* main window */
    GBLmainWindow = gtk_application_window_new(app);
    gtk_window_set_default_size(GTK_WINDOW(GBLmainWindow), 
                                GBLappSettings.windowWidth, GBLappSettings.windowHeight);
    gtk_window_set_title(GTK_WINDOW(GBLmainWindow), "ISO Master");
    gtk_window_set_icon(GTK_WINDOW(GBLmainWindow), appIcon); /* NULL is ok */
    g_signal_connect(G_OBJECT(GBLmainWindow), "close-request",
                     G_CALLBACK(closeMainWindowCbk), NULL);
    
    mainVBox = gtk_vbox_new(FALSE, 0);
    gtk_container_add(GTK_CONTAINER(GBLmainWindow), mainVBox);
    
    buildMenu(mainVBox);
    
    buildMainToolbar(mainVBox);
    
    buildFsLocator(mainVBox);
    
    mainFrame = gtk_frame_new(NULL);
    gtk_frame_set_shadow_type(GTK_FRAME(mainFrame), GTK_SHADOW_IN);
    gtk_box_pack_start(GTK_BOX(mainVBox), mainFrame, TRUE, TRUE, 0);
    
    GBLbrowserPaned = gtk_vpaned_new();
    gtk_container_add(GTK_CONTAINER(mainFrame), GBLbrowserPaned);
    gtk_paned_set_position(GTK_PANED(GBLbrowserPaned), GBLappSettings.topPaneHeight);
    
    topPanedBox = gtk_vbox_new(FALSE, 0);
    gtk_paned_pack1(GTK_PANED(GBLbrowserPaned), topPanedBox, TRUE, FALSE);
    
    buildFsBrowser(topPanedBox);
    
    bottomPanedBox = gtk_vbox_new(FALSE, 0);
    gtk_paned_pack2(GTK_PANED(GBLbrowserPaned), bottomPanedBox, TRUE, FALSE);
    
    buildMiddleToolbar(bottomPanedBox);
    
    buildIsoLocator(bottomPanedBox);
    
    buildIsoBrowser(bottomPanedBox);
    
    statusBar = gtk_statusbar_new();
    gtk_box_pack_start(GTK_BOX(mainVBox), statusBar, FALSE, FALSE, 0);
    
    if(GBLisoFileToOpen != NULL)
        openIso(GBLisoFileToOpen);
    
    gtk_window_present(GTK_WINDOW(GBLmainWindow));
}

int main(int argc, char** argv)
{
    int status;
    
    /* if --help passed, return usage help and quit */
    if (argv[1] != NULL)
    {
        if(strcmp(argv[1], "--help") == 0)
        {
            printf("Usage: isomaster [image.iso]\n");
            return 0;
        }
        GBLisoFileToOpen = argv[1];
    }
    
#ifdef ENABLE_NLS
    /* initialize gettext */
    bindtextdomain("isomaster", LOCALEDIR);
    bind_textdomain_codeset("isomaster", "UTF-8"); /* so that gettext() returns UTF-8 strings */
    textdomain("isomaster");
#endif
    
    findHomeDir();
    
    loadSettings();
    
    loadIcons();
    
    /* set up the signal handler for exiting editors and viewers */
    signal(SIGUSR1, sigusr1);
    signal(SIGUSR2, sigusr2);
    
    /* make sure children don't become zombies */
    signal(SIGCHLD, SIG_IGN);
    
#ifndef HAVE_ARC4RANDOM
    srandom((int)time(NULL));
#endif
    
    GBLapp = gtk_application_new("org.littlesvr.ISOMaster", G_APPLICATION_DEFAULT_FLAGS);
    g_signal_connect(GBLapp, "activate", G_CALLBACK(activate), NULL);
    status = g_application_run(G_APPLICATION(GBLapp), argc, argv);
    g_object_unref(GBLapp);
    
    return status;
}
