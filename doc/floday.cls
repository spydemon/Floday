\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{floday}[2017/05/11, v1.0]
\LoadClass[a4paper, 10pt]{article}

\usepackage{amssymb}			% Provide more characters.
\usepackage{calc}				% For alowing calculation like \textwidth+1cm.
\usepackage{charter}			% Font to use.
\usepackage{etoolbox}			% Manage conditions.
\usepackage{mdframed}			% Add possibility to draw box with a background color.
\usepackage[top=2cm, bottom=2cm, left=5cm, right=1cm]{geometry} %Set margins.
\usepackage[utf8]{inputenc}		% Use UTF-8 encoding.
\usepackage{lastpage}			% Provide the number of the last page of the document.
\usepackage{lmodern}			% Use vectorial typo instead of bitmap ones.
\usepackage{sidenotes}			% Manage sidenotes.
\usepackage[pagestyles]{titlesec}			% Customize titles section.
\usepackage[table]{xcolor}				% Provide color management (should be loaded before "tocstyle")
\usepackage{tocstyle}			% Provide ability to customize toc.
\usepackage[obeyspaces]{url}

% Decration of variables.
\newtoggle{optionFr}
\newtoggle{optionPrinted}
\newcounter{authorsNumber}
\reversemarginpar				%Command from marginnote package that put margin text at the left.
\geometry{marginparwidth={3.7cm}} % Set margin width.

% Declaration of colors
\definecolor{backgroundIntroduction}{RGB}{237, 237, 237}
\definecolor{table_one}{RGB}{255, 255, 255}
\definecolor{table_two}{RGB}{237, 237, 237}

\def \compilationDateLabel {Compilation date}
\def \softwareVersionReferenceLabel {Software reference version}

% Process option assigned to the template.
\DeclareOption{fr}{\toggletrue{optionFr}}
\DeclareOption{printed}{\toggletrue{optionPrinted}}
\ProcessOptions

% Manage "fr" option.
\iftoggle{optionFr}{%
	\usepackage[francais]{babel}	% Set all pregenerated text and typo convetion to french.
	\usepackage{caption}
	\usepackage[T1]{fontenc}		% Set French word splitting rules.
	\def \compilationDateLabel {Date de compilation}
	\def \softwareVersionReferenceLabel {Version logicielle de référence}
}

\usepackage[colorlinks]{hyperref}	% Make internal links in the document.
\usepackage{glossaries}				%Should be after babel loading.
\usepackage{wasysym}				% Provide more characters.

% Manage "printed" option.
\iftoggle{optionPrinted}{%
	\definecolor{backgroundIntroduction}{RGB}{255, 255, 255}
	\definecolor{table_one}{RGB}{255, 255, 255}
	\definecolor{table_two}{RGB}{255, 255, 255}
}

% Custom variables
\def\email#1{\def\@email{#1}}
\def\footer#1{\def\@footer{#1}}
\def\subtitle#1{\def\@subtitle{#1}}
\def\versionReference#1{\def\@versionReference{#1}}

% Draw title part of the document.
\def\maketitle{
	\newgeometry{top=2cm, bottom=2cm, right=2cm, left=2cm}
	\begin{center}
		{\sc \Huge \textbf{\@title}}\\
		\ifdefvoid{\@subtitle}{}{%
			{\sc \huge \@subtitle}\\
		}
		\vskip 0.2cm
		{\huge $\sim \bullet \backsim$}
		\vskip 0.2cm
		\begin{tabular}{lr}
			\compilationDateLabel{}          & \@date             \\
			\ifdefvoid{\@versionReference}{}{% Only display the version reference line if the variable is not empty.
				\softwareVersionReferenceLabel{} & \@versionReference \\
			}
		\end{tabular} \\
		\vskip 0.2cm
		{\textit {\@author}}
		$<${\texttt{\@email}}$>$%
		\vskip 1cm
		\thispagestyle{empty}
	\end{center}
}

% Customization of section titles
\titlespacing*{\section}{.0001pt}{.0001pt}{-14.5pt}
\titleformat{\section}[display]
  {}
  {}
  {0pt}
  {\colorsection}
\newcommand{\colorsection}[1]{%
	\setlength{\parskip}{0pt}
	\setlength{\fboxsep}{0pt}
	\vspace*{-1cm}
	\hspace*{\dimexpr-\marginparwidth-\marginparsep\relax}
	\colorbox{backgroundIntroduction}{%
		\begin{minipage}{\dimexpr\marginparwidth+\marginparsep+\textwidth\relax}
			\titlerule[1pt]
			\vspace{1pt}
			\titlerule
			\vspace{10pt}
			{\Large\filcenter\bfseries#1\\}
			\vspace{10pt}
			\titlerule
		\end{minipage}
	}
}

% Customization of the footer
\newpagestyle{default}{%
	% Here, we create a new box at the left of the cursor (llap) that has the
	% size of the margin plus the margin separator. We put the left part of the
	% footer inside it. The effect is that the margin is "avoided" for the footer.
	\setfoot{\llap{\makebox[\marginparwidth+\marginparsep][l]{%
		\sc \sectiontitle{} --- \subsectiontitle}
	}}{}{\thepage \slash \pageref{LastPage}}
}
\pagestyle{default}

% TOC customization.
\renewcommand\tableofcontents{%
	\vskip 1cm
	{\Large{\textbf \contentsname}}
	\vskip 0.2cm
	\@starttoc{toc}%
	\restoregeometry
}

% Table customization
\rowcolors{2}{table_one}{table_two}

%%%%%%%%%%%%%%%%%%
%% New commands %%
%%%%%%%%%%%%%%%%%%

%%%% Introduction block after each section.
\mdfdefinestyle{styleIntroduction}{%
	backgroundcolor=backgroundIntroduction,
	leftline=false,
	rightline=false,
	skipabove=5pt,
	topline=false
}

\newenvironment{intro} {
	\vspace{-.04cm}
	\hspace*{\dimexpr-\marginparwidth-\marginparsep-.6cm\relax}
	\begin{minipage}{\dimexpr\textwidth+\marginparwidth+\marginparsep}
	\bfseries
	\setlength{\parskip}{0pt}
	\begin{mdframed}[style=styleIntroduction]
  }
  {
	\end{mdframed}
	\end{minipage}
  }

%%%% Exists still
\newcommand\existstill[1]{%
	{\footnotesize
		\marginnote{#1}
	}
}

\newcommand\lastupdated[1]{%
	{\footnotesize
		\marginnote{#1}[13pt]
	}
}

\endinput
