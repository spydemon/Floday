\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{floday}[2017/05/11, v1.0]
\LoadClass[a4paper, 11pt]{article}

\usepackage{amssymb}			% Provide more characters.
\usepackage{etoolbox}			% Manage conditions.
\usepackage{mdframed}			% Add possibility to draw box with a background color.
\usepackage[top=2cm, bottom=2cm, left=2cm, right=2cm]{geometry} %Set margins.
\usepackage[utf8]{inputenc}		% Use UTF-8 encoding.
\usepackage{lmodern}			% Use vectorial typo instead of bitmap ones.
\usepackage{titlesec}			% Customize titles section.
\usepackage{xcolor}				% Provide color management (should be loaded before "tocstyle")
\usepackage{tocstyle}			% Provide ability to customize toc.
\usepackage{wasysym}			% Provide more characters.

% Decration of variables.
\newtoggle{optionFr}
\newtoggle{optionPrinted}
\newcounter{authorsNumber}

% Declaration of colors
\definecolor{backgroundIntroduction}{RGB}{200, 200, 200}

\def \compilationDateLabel {Compilation date}
\def \softwareVersionReferenceLabel {Software reference version}

% Process option assigned to the template.
\DeclareOption{fr}{\toggletrue{optionFr}}
\DeclareOption{printed}{\toggletrue{optionPrinted}}
\ProcessOptions

% Manage "fr" option.
\iftoggle{optionFr}{%
	\usepackage[francais]{babel}	% Set all pregenerated text and typo convetion to french.
	\usepackage[T1]{fontenc}		% Set Frensh word splitting rules.
	\def \compilationDateLabel {Date de compilation}
	\def \softwareVersionReferenceLabel {Version logicielle de référence}
}

% Manage "printed" option.
\iftoggle{optionPrinted}{%
	\definecolor{backgroundIntroduction}{RGB}{255, 255, 255}
}

% Custom variables
\def\email#1{\def\@email{#1}}
\def\footer#1{\def\@footer{#1}}
\def\subtitle#1{\def\@subtitle{#1}}
\def\versionReference#1{\def\@versionReference{#1}}

% Draw title part of the document.
\def\maketitle{
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
	\pagebreak
	\setlength{\parskip}{0pt}
	\setlength{\fboxsep}{0pt}
	\colorbox{backgroundIntroduction}{%
		\begin{minipage}{\textwidth}
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

% TOC customization.
\renewcommand\tableofcontents{%
	\vskip 1cm
	{\Large{\textbf \contentsname}}
	\vskip 0.2cm
	\@starttoc{toc}%
}

%%%%%%%%%%%%%%%%%%
%% New commands %%
%%%%%%%%%%%%%%%%%%
\mdfdefinestyle{styleIntroduction}{%
	backgroundcolor=backgroundIntroduction,
	leftline=false,
	rightline=false,
	skipabove=5pt,
	topline=false
}

\newenvironment{intro}
  {
	\bfseries
	\rightmargin 0.5cm
	\leftmargin 0.5cm
	\setlength{\parskip}{0pt}
	\begin{mdframed}[style=styleIntroduction]
  }
  {
	\end{mdframed}
  }
\endinput
