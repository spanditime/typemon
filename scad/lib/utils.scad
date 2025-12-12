function sum_array(arr, index) = 
  (index < 0) ? 0 : arr[index] + sum_array(arr, index - 1);

// Wrapper function for convenience
function total_sum(arr) = sum_array(arr, len(arr) - 1);