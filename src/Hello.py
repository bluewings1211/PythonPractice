# -*- coding: utf-8 -*-
"""
.. module:: Hello
   :synopsis: A simple module for printing "Hello"
 
.. moduleauthor:: Jeff Chan
 
"""
 
def print_hello_with_name(name):
    """This function prints hello with a name
 
    Args:
       name (str):  The name to use.
 
    Returns:
       int.  The return code::
 
          0 -- this always return 0
 
    Raises:
       AttributeError, KeyError
 
    A really simple function. Really!
 
    >>> print_hello_with_name('foo')
    Hello, foo
 
    """
    print 'Hello', name
    return 0
