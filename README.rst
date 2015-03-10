==========================
IDL Job Parallel Framework
==========================
:Document Author: Luke Domanski, CSIRO, IM&T, Scientific Computing
:Document Format: This document was written in reStructuredText_. There a
                  numerous converters and generators for `exporting from
                  reStructuredText`_ to pretty document formats.

.. _reStructuredText: http://docutils.sourceforge.net/rst.html
.. _exporting from reStructuredText: http://docutils.sourceforge.net/docs/user/links.html#export

.. contents:: Contents

-----------------------

Introduction
============
.. _start-short-overview:

A generic framework developed for generating job parallel ``jobs`` [#]_ for
parallel platforms based on a user defined (calling application) set of
preprocessing, work, and postprocessing IDL executables or routines, as well as
a list of application tasks to perform with parallel workers.

Different target parallel platforms are supported via job generator plugins.

The parallel job can be configured and generated on *any* machine running IDL
or GDL, for execution on a *remote* parallel machine supported by the chosen
plugin. The generated job directory can then be copied to the remote parallel
machine, and the job executed in a standalone fashion.

.. NOTE::
   The machines used for generation and execution could potentially be the same
   machine.

.. [#] i.e. the method of parallism utilised in the generated job is "job
   level parallelism" as opposed to a finer grained parallelism
.. _end-short-overview:


Software requirements and files
===============================

Environment and licensing requirements
--------------------------------------
Compilation
    - IDL + IDL Development Licence

Client Runtime Usage
    - IDL + IDL Runtime Licence minimum

Remote Job Execution
    - IDL + IDL Runtime Licence
    - GDL (optional alternative, see below)

Some job generator plugins support launching of worker processes using the open
source GDL implementation of the IDL language and environment. The **REMOTE**
user application to be run on the parallel machine must support IDL versions
<7.1 (at time of writing) to utilise GDL.

.. IMPORTANT::
   Unfortunately, the Job Parallel Framework API currently requires
   functionality not provided by GDL to switch between job generator plugins.
   Therefore, the **CONTROLLER/CLIENT** user application can not be run using
   GDL.

Collecting required packages
----------------------------
You will required the source packages to compile this software. Which can be
downloaded from the Subversion source code repository at::

    https://svnserv.csiro.au/svn/dom039/Parallel_Framework/trunk

Compilation and Setup
=====================

Compiling the code and documentation
------------------------------------
The compilation is a two part process carried out on **both** the *client* and
*remote* machines:

1. Compile The IDL Job Parallel Framework and Documentation

   See `Compiling the Job Parallel Framework`_

2. Add the IDL Job Parallel Framework installation directory to your ``IDL_PATH``
   and ``GDL_PATH``

   See `Setting IDL_PATH`_ and `Setting GDL_PATH`_

The package can be installed as a source-binary combination, or as a binary
only installation.

Compiling the Job Parallel Framework
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
The compilation processes has been automated in the
``build/build_parframewrk.pro`` and ``build/build_docs.pro`` scripts.

To compile:

1. Start an IDL Development Environment
2. Change to the Parallel_Framework base directory
3. Run the build scripts::

    > @build/build_parframewrk
    > @build/build_docs

``build_parframewrk`` creates two types of binaries in the Parallel_Framework's
``bin`` directory:

The IDL Job Parallel Framework Library & API(``bin/par_framework.sav``)
    whose functions/procedures you can call from other IDL programs to discover
    information about available job generators and generate parallel jobs

Job generator plugins (``bin/plugins/*.sav``)
    which contain compiled versions of the job generator plugins present in
    the Parallel_Framwork's ``src/plugins/`` directory. The plugins are loaded
    on demanded by ``par_framework.sav`` to generate different type of job
    output. They should not be called directly by user applications.

.. admonition:: OPTIONAL

   *Not compatible with GDL usage!*
   To provide a binary only installation of the framework, delete the package's
   ``src`` directory after compilation.

``build_docs`` generates IDL html help files from the header comment blocks
of functions and procedures in the IDL Job Parallel Framework source code, and
places them in the ``doc/reference`` directory.

You can then view the output html files individually in a web browser. See
the `Reference Manual`_ section of this document for table of contents.

Setting IDL_PATH
~~~~~~~~~~~~~~~~
For other applications to use the framework, you must make the Parallel
Framework Library visible on the IDL ``!PATH``.

To do this, append ``+<path_to_Parallel_Framework>/bin`` and
``+<path_to_Parallel_Framework>/src`` to the ``IDL_PATH`` system or user
environment variable, where "<path_to_Parallel_Framework>" is a place holder
for the real directory path.

.. IMPORTANT::
   The resulting ``IDL_PATH`` must contain the special token ``<IDL_DEFAULT>``
   for IDL internal use. It is recommend you include this token when appending
   to ``IDL_PATH``.

.. TIP::
   If providing a binary only installation of the framework, then
   ``+<path_to_Parallel_Framework>/src`` can be omitted from the ``IDL_PATH``

On Linux derivative systems
+++++++++++++++++++++++++++
Use your shell's provided mechanism for setting environment variables.

e.g. For bash::

> export IDL_PATH=${IDL_PATH}:<IDL_DEFAULT>:+<path_to_Parallel_Framework>/bin:+<path_to_Parallel_Framework>/src

e.g. For tcsh::

> setenv IDL_PATH ${IDL_PATH}:<IDL_DEFAULT>:+<path_to_Parallel_Framework>/bin:+<path_to_Parallel_Framework>/src

Place this command in your user shell start-up script to ensure it is set on
every login. e.g. ``.bashrc`` (bash), ``.cshrc`` (tcsh), ``.profile``, etc.
This file will be system and shell dependant, please check your system
administrator's policy/recommendation.

On modern Windows systems
+++++++++++++++++++++++++
In the ``Systems Properties`` menu, accessible via
"Control Panel>System and Security>System>Change Settings" or similar:

1. click "Advanced Tab>Environment Variables..."
2. to append an existing ``IDL_PATH``

   a) Select the ``IDL_PATH`` variable in either the "User variables" or
      "System variables" section
   b) click "Edit.."
   c) enter ``;+<path_to_Parallel_Framework>/bin:+<path_to_Parallel_Framework>/src;<IDL_DEFAULT>``
      after the existing text in the "Variable value" text box (**note the leading semi-colon!**)

3. **OR** to specify a new ``IDL_PATH`` variable if necessary

   a) click "New.." in either the "User variables" or "System variables" section
   b) enter ``IDL_PATH`` into the "Variable name" text box
   c) enter ``+<path_to_Parallel_Framework>/bin:+<path_to_Parallel_Framework>/src;<IDL_DEFAULT>``
      in the "Variable value" text box (**note absence of leading semi-colon!**).

.. WARNING::
   "System variables" will apply to all users of the system.

.. NOTE::
   Depending on your system privileges, you might only be able to add or edit the "User variables".

Setting GDL_PATH
~~~~~~~~~~~~~~~~
If you will be using GDL to run remote parallel workers, then you **must**
install the Job Parallel Framework **source code** on the remote machine. i.e. you
cannot provide the optional **binary only** installation mentioned in
`Compiling the Job Parallel Framework`_.

Append ``+<path_to_Parallel_Framework>/src`` to the ``GDL_PATH`` environment
variable following similar steps to those outlined in `Setting IDL_PATH`_, e.g.
for Linux bash::

> export GDL_PATH=${GDL_PATH}:+<path_to_Parallel_Framework>/src

.. NOTE::
   For GDL you do not need to add the ``<IDL_DEAFAULT>`` token.

Documentation
=============
If you have not yet followed the instructions in the `Compiling the
code and documentation`_ section, please do so.

User Manual & Tutorial
----------------------
The Job Parallel Framework can be used in two modes:

By the **generator application**
    To generate parallel jobs using the ``generate_parallel_job`` procedure

By the **remote** worker(s)
    To take advantage of Job Parallel Framework helper functions which simplify
    worker application development

For details on usage please see the `User Guide`_ and `Tutorial`_.

.. _User Guide: doc/user_guide/user_guide.html
.. _Tutorial: doc/user_guide/user_guide.html#tutorial

Extending the IDL Job Parallel Framework
----------------------------------------
The framework can be extended through user defined job generator plugins which
allow for a broad range of target platforms and job management systems to be
supported through a single library API.

The generator plugins **MUST** implement the `plugins interface`_ described in
the `developer guide`_ and also the `par_framework.pro`_ documentation.

.. _plugins interface: doc/user/developer_guide.html#plugins
.. _developer guide: doc/user/developer_guide.html
.. _par_framework.pro: doc/reference/par_framework.html#par_framework_pro

Reference Manual
----------------
- IDL Job Parallel Framework

  + `par_framework.pro - IDL Job Parallel Framework <doc/reference/par_framework.html#par_framework_pro>`_
  + `pbs_job_generator.pro - IDL Job Parallel Framework PBS+Linux plugin for non-array job versions of PBS <doc/reference/pbs_job_generator.html#pbs_job_generator_pro>`_
  + `pbs_job_array_job_generator.pro - IDL Job Parallel Framework PBS+Linux plugin <doc/reference/pbs_job_array_job_generator.html#pbs_job_array_job_generator_pro>`_

