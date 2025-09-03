part of 'custom_widget.dart';
class CustomRatingIndicator extends StatelessWidget {
  final double rating;
  final double? iconSize;
  const CustomRatingIndicator({super.key, required this.rating, this.iconSize});

  @override
  Widget build(BuildContext context) {
    return RatingBarIndicator(
      rating: rating,
      itemBuilder: (context, index) => SvgPicture.asset(AppIcons.ratingIcon),
      itemCount: 5,
      itemPadding: EdgeInsets.all(2),
      itemSize: iconSize ?? 12.0,
      
      direction: Axis.horizontal,
    );
  }
}