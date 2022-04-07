<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" href="../../style.css"/>
	<link rel="shortcut icon" type="image/x-icon" href="../pix/favicon.ico"/>
	<title>Selfhosted git server</title>
</head>
<body>
	<div class="main">
		<div class="header">
			<p>
			<a href="../../index.php">
			Unixfandom.com
			<img src="../../files/pix/penguin.gif" alt="penguin_gif">
			</a>
			</p>
		</div>

		<nav>
			<?php include '../navigation.php';?>
		</nav>
	<h1>Selfhosted git server</h1>
	<p>
	This is mostly copied from <a href="https://www.linux.com/training-tutorials/how-run-your-own-git-server/">this tutorial</a>.<br>
	I added somethings they didn't touch on, such as adding the remote with a non-default ssh port and key.</p>

	<h3>Dependencies</h3>
	<pre>
$ apt install git-core
	</pre>

	<h3>Creating a git user</h3>
	<p>
	We'll create a git user that has access our repositories and set him up with an ssh keys pair for secure authentication.<br>
	<pre>
# On the server:
$ useradd -m git
$ passwd git

# On the client:
$ ssh-keygen -t rsa
$ cat /path/to/id_rsa.pub | ssh git@remote-server "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"
	</pre>

	<h3>Creating repositories</h3>
	<p>
	The location of your git repository doesn't exactly matter.<br>
	Just make sure that your git user is the owner and has the permissions to access the files.
	</p>

	<pre>
$ mkdir /home/git/dwm.git
$ cd /home/git/dwm.git
$ git init --bare
	</pre>

	<h3>Adding our remote repository to an existing repo</h3>
	<p>
	We'll create an ssh alias on the client machine that'll allow us to specify a port and ssh key.
	</p>
	<pre>
$ vim ~/.ssh/config

Host serv
    HostName example.com
    User git
    IdentityFIle /path/to/id_rsa
    Port 22

# Testing it out
$ ssh serv

git~&gt;
	</pre>
	<p>After that, we can add our url to our repository</p>
<pre>
$ git remote add remote-name git@serv:/home/git/dwm.git

# Testing
$ git add .
$ git push -u remote-name master
$ git clone git@serv:/home/git/dwm.git
</pre>

	<h3>DONE!</h3>
	<p>That's about it. It's pretty straight foward.<br>
	If you want to push your repository to multiple remotes, you can create a git alias as so:</p>
	<pre>
$ git config alias.pushall '!git push origin master && git push remote-name master'
$ git pushall
	</pre>
	</div>

	<div class="footer">
			<?php include '../footer.php';?>
	</div>
</body>
</html>
