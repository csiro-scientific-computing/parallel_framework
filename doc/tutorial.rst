:Document Author: Luke Domanski, CSIRO, IM&T, Scientific Computing
:Document Format: This document was written in reStructuredText_. There a
                  numerous converters and generators for `exporting from
                  reStructuredText`_ to pretty document formats.

.. _reStructuredText: http://docutils.sourceforge.net/rst.html
.. _exporting from reStructuredText: http://docutils.sourceforge.net/docs/user/links.html#export

============================
Using the Parallel Framework
============================

Preface
=======
This document gives a tutorial style overview of Job Parallel Framework usage.

For a brief listing of the most common usage commands see the `Quick
Reference`_. For detailed procedure and function documentation see the
`Reference Guide`_.

Where noted, examples from this document (including interactive commands) can be
found in the ``example/tutorial`` directory of the Job Parallel Framework
distribution, and assume that this is your current working directory.

Overview
========
Using the parallel framework requires three main steps:

1. Developing a user defined worker task function(s) in IDL; the application
   that gets run in parallel on the compute machine.
2. Generating a parallel job using the Job Parallel Framework API
3. Placing and running the parallel job on the compute machine

Before calling any Framework functions, you must run the framework loader
procedure to initialise your IDL or GDL session::

    load_par_framework

Developing worker task functions
================================
Worker task functions are IDL functions that perform the processing you wish to
carry out in parallel on the compute machine.

A worker function:

1. Takes the description of a task to perform as an IDL structure, where the
   fields of the structure represents the input parameters for an individual
   application task.
2. Returns a structure representing the output details of the task performed.

The Job Parallel Framework knows nothing about the implementation of worker
task functions, nor the format of the chosen task structures. It simply passes
a structure into the worker function and expects a structure to be returned.

Complex worker task functions might require more information than the task list
to direct processing. The Job Parallel Framework provides the
`parse_worker_command_line_args`_ helper routine that will retrieve commandline
parameters passed to the parent worker process that called the task function.
In most cases this additional information is not required.

Worker task function example
----------------------------
Imagine we have some IDL code that sums two vector arrays stored in a pair of
IDL save files, then finds the mean and standard deviation of the result.

We might implement this as follows[#sms_pro]_::

    pro sum_mean_stddev, fname_arrayA, fname_arrayB, m, s
        restore, fname_arrayA
        restore, fname_arrayB
        m=mean(A+B)
        s=stddev(A+B)
    end

.. [#sms_pro] This procedure and its documentation are in
   ``examples/tutorial/sum_mean_stddev.pro``

Now imagine we have thousands of such tasks we wish to perform, and we want to
use the Job Parallel Framework to perform these individual tasks in parallel.
To do this we must create a worker task function that implements an interface
compatible with the Job Parallel Framework, in particular, that takes a task
structure.

The easiest way to do this is to write a wrapper task function around the core
``sum_mean_stddev`` processing procedure as follows[#sms_pfw]_::

    function sum_mean_stddev_pfw, task, subdivision
        sum_mean_stddev, task.filename_A, task.filename_B, m, s
        out_item={output, mean:m, stddev:s}
        return, out_item
    end

.. [#sms_pfw] This function and its documentation are in
   ``examples/tutorial/sum_mean_stddev_pfw.pro``

Here we have chosen our task structure representation holding the names of the two
input files to be::

    task={task, filename_A:'', filename_B:''}

We will need to utilises this same structure when defining the job wide task
list in order to `Generate the parallel job`_.

.. NOTE::
   We have not called `parse_worker_command_line_args`_ in the above example.
   We only need to call this function if we wish to access *additional* details
   about the overall worker process.

Generate the parallel job
=========================
Once we have created a worker function that can process a single task allocated
to it by the Parallel Framework, we can generate parallel jobs using it.

Achieving this requires three main steps:

1. Create an array of task structures representing the **global** task list
   that will be shared between parallel workers
2. **Optionally** load the desired job generator for the target parallel
   platform using the `load_generator_plugin`_ function
3. Generate parallel job files by calling the `generate_parallel_job`_
   function, specifying the global task list, worker task function, and desired
   number of parallel workers

The `generate_parallel_job`_ function will break the global task list into
individual worker task lists based on the number of parallel workers requested,
and generate all the scripts and files required to launch the parallel worker processes
on the target platform. When the job is run, the worker processes will call on
the specified worker task function to process each of its assigned tasks.

Job generation example
----------------------
Global task list
~~~~~~~~~~~~~~~~
We will first create an array of appropriate structures and populate them with
the global list of tasks.

As discussed in the `Worker task function example`_ section, each task will be
represented by the structure[#task_list]_::

    t={task, filename_A:'', filename_B:''}

Which holds the pair of file paths for the IDL save files operated on in each task.

Lets assume we have daily input data for a 31 day study, stored in the
directory ``/research/studyresults/`` on the target compute machine. And that
each pair of files is named ``<D>_male.sav`` and ``<D>_female.sav``, where
``<D>`` is a number representing the day of the study these files hold results
for.

The code for populating the global task list might then look like this[task_list]_::

    g_task_list=REPLICATE({task}, 31)
    g_task_list.filename_A="/research/studyresults/"+STRTRIM(STRING(INDGEN(31)),2)+"_male.sav"
    g_task_list.filename_B="/research/studyresults/"+STRTRIM(STRING(INDGEN(31)),2)+"_female.sav"

.. [#task_list] This example code can be found in
   ``example/tutorial/create_task_list.pro`` and run from IDL with
   ``g_task_list=create_task_list()``

Selecting job generator
~~~~~~~~~~~~~~~~~~~~~~~
The Job Parallel Framework supports a potentially unlimited number of parallel
platforms through user definable job generator plugins.

The framework is distributed with generators for Linux PBS and PBS array jobs,
and **the PBS generator** ``pbs_job_generator`` **is loaded by default** when
``load_par_framework`` is called.

To change from the default generator, get a list of available generators and
their descriptions using the helper function `discover_generator_plugins`_. And
load one by passing its identifier string to the `load_generator_plugin`_
function, e.g. the default::

    load_generator_plugin, plugin_ident="pbs_job_generator"

Generating The Job
~~~~~~~~~~~~~~~~~~
To generate the actual job files, we call `generate_parallel_job`_ specifying the[#gen_job]_:

- global task list
- destination job file directory (optional: default current directory)
- name of the IDL worker task function to run on each task
- the desired number worker processes to utilise

::

    generate_parallel_job, task_params=g_task_list, job_dir="./parallel_job", $
                           work_func="sum_mean_stddev_pfw", n_workers=8

.. [#gen_job] This example code can be found in
   ``example/tutorial/create_parallel_job.pro`` and run from IDL with
   ``create_parallel_job, g_task_list=g_task_list``

You will now find a number of files in the ``parallel_job`` directory required
to run the job in parallel on a compute machine.

Staging data and program files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Data files
^^^^^^^^^^
The Job Parallel Framework knows little about the application's task
functions or structures (see `Developing worker functions`_). It doesn't even
know if strings in the task structure represent files! e.g.
``g_task_list.filename_A`` and ``g_task_list.filename_B`` in our example.

Therefore, local data files named in the global tasks list are not staged
automatically to the compute system. If your task structure refers to data files,
it is your responsibility to ensure they are available at the specified location
on the compute machine.

The `generate_parallel_job`_ procedure provides a primitive mechanism to assist
with this through its ``bundle_data`` and ``data_dest`` parameters.
``bundle_data`` accepts an array of filename strings to copy to the generated
job directory, while ``data_dest`` specifies a relative subdirectory of the job
directory to copy the files in to. One can then refer to these data files
from the global task list using filename paths relative to the job directory.

For example, the ``gen_test_data`` procedure in the
``example/tutorial/data/gen_test_data.pro`` file will output some data files
in to ``example/tutorial/data/research/studyresults`` for testing our parallel
``sum_mean_stddev`` job.

We can then modify our previously created ``g_task_list`` and
``generate_parallel_job`` call to ensure these files are copied to the job
directory and used in calculations[#gen_job_data]_::

    g_task_list.filename_A="."+g_task_list.filename_A
    g_task_list.filename_B="."+g_task_list.filename_B
    generate_parallel_job, task_params=g_task_list, job_dir="./parallel_job", $
                           work_func="sum_mean_stddev_pfw", n_workers=8, $
                           bundle_data=FILE_SEARCH("data/research/studyresults/*.sav"),$
                           data_dest="research/studyresults"

.. [#gen_job_data] This example code can be found in
   ``example/tutorial/create_parallel_job_data.pro`` and run from IDL with
   ``create_parallel_job_data, g_task_list=g_task_list``

Program files
^^^^^^^^^^^^^
By default the Framework **will** copy ``.pro`` (source) and/or ``.sav``
(compiled) module files to the job directory, for worker task functions named in
the call to `generate_parallel_job`_. But will not copy every module or code
file this function depends on.

You must ensure that either:

1. ``.pro`` or ``.sav`` files of all code/libraries required to run your worker
   functions are installed on the compute machine and visible on the IDL or GDL
   search path (includes the job directory).
2. the compiled ``.sav`` file for you functions include all dependencies within
   the file (see IDL documentation) prior to calling `generate_parallel_job`_.

.. NOTE::
   The option selected depends on the execution environment and license used to
   run the parallel jobs. e.g. IDL runtime licence only permits ``.sav`` (option
   1 or 2) while GDL only supports ``.pro`` (option 1 only)

To assit with *option 1* `generate_parallel_job`_ provides a ``bundle_prog``
parameter to specify an array of filename strings (particularly IDL ``.pro`` and
``.sav`` files) to copy to the job directory. These files are copied to the base
``job_dir``, as this will be the first location checked in the IDL & GDL search
paths.

`generate_parallel_job`_ has no mechanism to assit with *option 2*. This is
achieved via the method you use to compile you ``.sav`` files.

Option 1 example
................
For `sum_mean_stddev_pfw`_ to run correctly under GDL, it will require access to
the source ``.pro`` file containing `sum_mean_stddev`_. `generate_parallel_job`_
will not copy this additional source file to the job directory automatically. We
can ensure it does via the ``bundle_prog`` argument[#gen_job_prog]_::

    generate_parallel_job, task_params=g_task_list, job_dir="./parallel_job", $
                           work_func="sum_mean_stddev_pfw", n_workers=8, $
                           bundle_data=FILE_SEARCH("data/research/studyresults/*.sav"),$
                           data_dest="research/studyresults", $
                           bundle_prog=["sum_mean_stddev.pro"]

.. [#gen_job_prog] This example code can be found in
   ``example/tutorial/create_parallel_job_prog.pro`` and run from IDL with
   ``create_parallel_job_prog, g_task_list=g_task_list``

Option 2 example
................
To ensure the `sum_mean_stddev_pfw`_ task function runs correctly using IDL, we
could compile it and all its dependencies into a ``.sav`` file, and rely on
`generate_parallel_job`_ to copy the ``.sav`` file to the job
directory[#gen_job_comp]_ (compilation not available in GDL)::

    RESOLVE_ROUTINE, "sum_mean_stddev_pfw", /IS_FUNCTION, /COMPILE_FULL_FILE
    RESOLVE_ALL, RESOLVE_FUNCTION=SUM_MEAN_STDDEV_PFW, /CONTINUE_ON_ERROR
    SAVE, /ROUTINES, filename="sum_mean_stddev_pfw.sav"
    generate_parallel_job, task_params=g_task_list, job_dir="./parallel_job", $
                           work_func="sum_mean_stddev_pfw", n_workers=8, $
                           bundle_data=FILE_SEARCH("data/research/studyresults/*.sav"),$
                           data_dest="research/studyresults"

.. [#gen_job_comp] This example code can be found in
   ``example/tutorial/create_parallel_job_comp`` and run from IDL with
   ``create_parallel_job_comp, g_task_list=g_task_list``

Run the job on a parallel computer
==================================
To run the job the ``parallel_job`` directory must be placed in a location
accessible to the compute machine running the job. If you have not copied the
job directory to the target machine's file systems, you will need to do so
following the procedures available for your operating system and the compute
machine.

Once the job directory is accessible from the compute machine, change to the job
directory and run the control script, whose name will match the ``job_name``
passed to `generate_parallel_job`_ (default ``pfwjob``), e.g. (here we assume
Linux)::

    > cd parallel_job
    > ./pfwjob.sh

The output (output work item array) of each worker will be saved to a file
``<job_name>_subresultlist<N>.sav`` and can be loaded and viewed within IDL or
GDL (e.g. for the first worker)::

    restore, "pfwjob_subresultlist0.sav"
    print, work_items
        {      1.49833      1.41827}{      4.00698      1.38831}{      1.04715
              1.38655}{      1.65538      1.39901}

The control script may also take various commandline parameters depending on
the generator plugin used. You can check available options/parameters using::

    > ./pfwjob.sh --help

.. NOTE:: Linux parallel jobs may contain a ``job_env.sh`` file in the
   ``job_dir``. This is the location to place shell specific environment step up
   required by your worker processes.


