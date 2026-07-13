---
permalink: /instructors/key-pairs/windows/
title: Windows
parent: Key Pairs
grand_parent: Instructors
nav_order: 1
---
# Windows Key-Pair Generation Instructions

## Step 1: Install Git

1. Download and install [Git](https://git-scm.com/) on your machine. <http://git-scm.com/downloads>
2. Open **Git bash** by clicking the start menu and typing in “git bash”.

Windows 7:

![Search for "git bash" when you open your Start Menu in Windows 7](/images/key-pair-03.png)

Windows 8:

![After pressing the Windows Key or clicking the Start button start typing "Git bash" to search for the program](/images/key-pair-04.png)

## Step 2: Generate a new SSH key for MarkUs

1. Within the Git bash copy and paste the following text below. If you wish, you can add a label for your key pair. (ex: Laptop, School Computer, etc)
`> ssh-keygen -t rsa -C "LABEL GOES HERE"`
2. Leave the default options as is and keep pressing **Enter** until you see:
`Your identification has been saved in .../<yourUsername>/.ssh/id_rsa.`
`# Your public key has been saved in .../<yourUsername>/.ssh/id_rsa.pub.`

## Step 3: Add your key to your ssh-agent

An **ssh-agent** is a tool which keeps track of your private / public key pairs and will help authenticate you when you try to establish connections.

1. Now add your newly generated key to the ssh-agent by running this command:

    ```console
    > ssh-add ~/.ssh/id_rsa
    ```

    You should see something like:

    ```console
    Identity added: .../<yourUsername>/.ssh/id_rsa
    (.../<yourUsername>/.ssh/id_rsa)
    ```

**From now on, continue to use the Git bash for your Git commands on your Windows machine.**

## Step 4: Add your public key to MarkUs

1. Adding your public key to MarkUs is done by visiting this page and clicking “**New Key Pair**”
2. Now you can choose to upload the public key file itself (located in the hidden folder in your home directory `~/.ssh/id_rsa.pub` or by executing the following commands from within your **Git bash** to copy and paste your public key c$
`notepad ~/.ssh/id_rsa.pub`
Notepad will then open up and you can then copy the public key contents and paste it into Markus:

![Copy your public key contents.](/images/key-pair-05.png)

![Paste your public key contents into MarkUs.](/images/key-pair-06.png)
