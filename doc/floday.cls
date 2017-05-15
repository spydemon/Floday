\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{floday}[2017/05/11, v1.0]
\LoadClass[a4paper, 11pt]{article}

\usepackage{amssymb}			% Provide more characters.
\usepackage{etoolbox}			% Manage conditions.
\usepackage[top=2cm, bottom=2cm, left=2cm, right=2cm]{geometry} %Set margins.
\usepackage[utf8]{inputenc}		% Use UTF-8 encoding.
\usepackage{lmodern}			% Use vectorial typo instead of bitmap ones.
\usepackage{titlesec}			% Customize titles section.
\usepackage{tocstyle}
\usepackage{wasysym}			% Provide more characters.

% Decration of variables.
\newtoggle{optionFr}
\newcounter{authorsNumber}

\def \compilationDateLabel {Compilation date}
\def \softwareVersionReferenceLabel {Software reference version}

% Process option assigned to the template.
\DeclareOption{fr}{\toggletrue{optionFr}}
\ProcessOptions

% Manage "fr" option.
\iftoggle{optionFr}{%
	\usepackage[francais]{babel}	% Set all pregenerated text and typo convetion to french.
	\usepackage[T1]{fontenc}		% Set Frensh word splitting rules.
	\def \compilationDateLabel {Date de compilation}
	\def \softwareVersionReferenceLabel {Version logicielle de référence}
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
\titleformat{\section}[display]
	{\Large\filcenter}
	{}
	{1pc}
	{\pagebreak\titlerule[1pt] \vspace{1pt} \titlerule \vspace{5pt}}
	[\vspace{5pt}\titlerule]

% Test renaming toc
\renewcommand\tableofcontents{%
	\vskip 1cm
	{\Large{\textbf \contentsname}}
	\vskip 0.2cm
	\@starttoc{toc}%
%	\mbox{
%	\vspace{2pt}
%	{\centering\textbf{\Large\contentsname}}
%	\@mkboth{\MakeUppercase\contentsname}{\MakeUppercase\contentsname}%
%	\@starttoc{toc}%
%	}
}
\endinput
