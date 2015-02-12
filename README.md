![MarkUs logo] (http://markusproject.org/img/markus_logo_big.png)

Welcome to MarkUs! Online Marking Made Easy
===========================================

http://markusproject.org/

MarkUs is a web application for the submission and grading of student programming assignments. The primary purpose of MarkUs is to provide TAs with simple tools that will help them to give high quality feedback to students. MarkUs also provides a straight-forward interface for students to submit their work, form groups, and receive feedback. The administrative interface allows instructors to manage groups, organize the grading, and release grades to students.

Since 2008, more than 140 undergraduate students have participated in the development of MarkUs; some as full-time summer interns, but most working part time on MarkUs as a project course. The fact that we have have uncovered so few major bugs, and that MarkUs has been so well-received by instructors is a testament to the high quality work of these students. MarkUs is used in more than a dozen courses at the University of Toronto, in several courses at the University of Waterloo, and at École Centrale Nantes (in French).

MarkUs is written using Ruby on Rails, and uses Subversion (with a Git back-end in progress) to store the student submissions. 


## 1. Features

- Graders can easily annotate students' code (overlapping annotations, graded source code remains untouched)
- Subversion storage back-end
- Instructors can form teams
- Students can form groups on their own
- Supports different course models:

  - Web-based file upload for first-year courses
  - Subversion client commits for upper year courses (disabled Web-upload)
  - Allows students to work on code of other groups from one assignment to the next

- Web-based course administration
- One MarkUs application per course (independent databases across courses)

Please see the INSTALL file for installation instructions.


## 2. Links

- Email a security alert: <security@markusproject.org>
- Email a general inquiry: <info@markusproject.org>
- Blog: http://blog.markusproject.org/
- Sandbox: http://www.markusproject.org/admin-demo
- Source Code: http://github.com/MarkUsProject/Markus
- IRC Channel: irc://irc.freenode.net/#markus ([Logs](http://www.markusproject.org/irc/))
- Mailing list: <markus-users@cs.toronto.edu>


## 3. Sandbox

If you are interested in MarkUs and would like to try it out, there is a MarkUs sandbox installation available (http://www.markusproject.org/admin-demo). For information as to how to use the demo instance please see our "How to use the demo server" (http://blog.markusproject.org/?p=219) blog post. We hope you will enjoy it and please let us know how you liked it: info@markusproject.org.


## 4. System Requirements

- Rails 3.0/Ruby 1.9.3+ (2.1.2 recommended)
- Unicorn/Passenger
- PostgreSQL/MySQL
- Subversion

Note: As of now, the latest stable version is MarkUs 0.10.0. Here is our current
deployment/configuration documentation. Please send us email if you have any
trouble installing MarkUs---we'd be happy to help you out.


## 5. Who is Using MarkUs?

- Department of Computer Science, University of Toronto, Canada
- School of Computer Science, University of Waterloo, Canada
- École Centrale de Nantes, France


## 6. Staying in Touch

Want the latest MarkUs news? It's available several ways:

* General queries can be sent to <info@markusproject.org>.
* The development team has a blog at http://blog.markusproject.org.
* There is a mailing list for MarkUs users. You can also find us on IRC in the #markus channel on FreeNode.


## 7. Helping Out

Found a bug? Want a feature? Please email <info@markusproject.org>.


## 8. Credits

MarkUs grew out of OLM, which was build using the TurboGears framework. We are
grateful to everyone who worked on or funded both projects, and to the creators
of Ruby on Rails for building such a great framework.

MarkUs' development has been supported by the University of Toronto, École
Centrale de Nantes, et. al. Kudos to everyone who turned that support into
working code:

Aaron Lee, Adam Goucher, Aimen Khan, Alexander Kittelberger, Alexandre Lissy, Alex Grenier, Alex Krassikov, Alysha Kwok, Amanda Manarin, Andrew Hernandez, Andrew Louis, Angelo Maralit, Anthony Le Jallé, Anton Braverman, David Das, Arianne Dee, Benjamin Thorent, Benjamin Vialle, Bertan Guven, Brian Xu, Bryan Shen, Bryan Muscedere, Camille Guérin, Catherine Fawcett, Chris Kellendonk, Christian Jacques, Christian Millar, Christine Yu, Christopher Jonathan, Clément Delafargue, Clément Schiano, Danesh Dadachanji, Daniel St. Jules, Daniyal Liaqat, Daryn Lam, David Liu, Diane Tam, Dina Sabie, Dylan Runkel, Ealona Shmoel, Egor Philippov, Erik Traikov, Eugene Cheung, Evan Browning, Farah Juma, Fernando Garces, Gabriel Roy-Lortie, Gillian Chesnais, Geoffrey Flores, Hanson Wu, Haohan David Jiang, Horatiu Halmaghi, Ian Smith, Ibrahim Shahin, Ishan Thukral, Irene Fung, Jakub Subczynski, Jay Parekh, Jeffrey Ling, Jeremy Merkur, Jeremy Winter, Jérôme Gazel, Jiahui Xu, Jordan Saleh, Joseph Mate, Joseph Maté, Joshua Dyck, Junghwan Tom Choi, Justin Foong, Karel Kahula, Kitiya Srisukvatananan, Kurtis Schmidt, Lawrence Wu, Luke Kysow, Marc Bodmer, Marc Palermo, Mark Rada, Mark Kazakevich, Maryna Moskalenko, Mélanie Gaudet, Michael Lumbroso, Mike Conley, Mike Gunderloy, Mike Stewart, Mike Wu, Misa Sakamoto, Nathan ChowNeha Kumar, Nelle Varoquaux, Nicholas Maraston, Nicolas Bouillon, Nick Lee, Nicolas Carougeau, Noé Bedetti, Oloruntobi Ogunbiyi, Ope Akanji, Paymahn Moghadasian, Peter Guanjie Zhao, Rafael Padilha, Razvan Vlaicu, Robert Burke, Ryan Spring, Samuel Gougeon, Sean Budning, Severin Gehwolf, Shenglong Gao, Shion Kashimura, Simon Lavigne-Giroux, Stephen Tsimicalis, Su Zhang, Tara Clark, Tiago Chedraoui Silva, Tianhai Hu, Valentin Roger, Veronica Wong, Victoria Mui, Victoria Verlysdonk, Victor Ivri, Vivien Suen, William Roy, Xiang Yu, Yansong Zang, Yusi Fan, Zachary Munro-Cape

**Supervisors:** Karen Reid, Morgan Magnin, Benjamin Vialle, David Liu
