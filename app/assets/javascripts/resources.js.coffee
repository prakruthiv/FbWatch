###$(document).ready ->
  $(".chart-scoring-pie").each ->
    ctx = this.getContext("2d")
    myNewChart = new Chart(ctx).Pie([
      value: $(this).data('chart-data-mentions')
      color: "#F38630"
    ,
      value: $(this).data('chart-data-shared')
      color: '#69D2E7'
    ])
###