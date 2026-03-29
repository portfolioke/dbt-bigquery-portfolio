{% test assert_column_not_empty_string(model, column_name) %}

select *
from {{ model }}
where {{ column_name }} = ''
   or trim({{ column_name }}) = ''

{% endtest %}